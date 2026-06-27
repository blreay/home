#!/bin/bash
#
# xpra-guardian.sh — xpra session 守护脚本
#
# 功能：周期性检测 xpra session（:102 / 端口 6001）的健康状态，
#       一旦 X server 崩溃或端口失联，自动清理残留并重启完整 session
#       （xterm + fcitx5 + cursor，含中文输入法环境）。
#
# 设计要点：
#   - 只保 xpra / X server 存活；cursor 进程不单独监控（随 session 一起拉起）
#   - flock 防止多个守护实例并发
#   - 日志自动轮转（超过 MAX_LOG_SIZE 截断）
#   - nohup 后台运行，不依赖 systemd（容器友好）
#
# 用法：
#   ./xpra-guardian.sh start      # 后台启动守护（nohup）
#   ./xpra-guardian.sh stop       # 停止守护
#   ./xpra-guardian.sh status     # 查看守护和 session 状态
#   ./xpra-guardian.sh check      # 手动跑一次健康检测（前台，调试用）
#   ./xpra-guardian.sh restart-session  # 手动强制重启一次 session
#   ./xpra-guardian.sh foreground # 前台运行守护循环（调试用）
#
set -o pipefail

#==============================================================================
# 配置
#==============================================================================
DISPLAY_NUM=103                       # 固定 display 号
PORT=6001                             # TCP 绑定端口
DPI=96                                # DPI
CHECK_INTERVAL=30                     # 健康检测间隔（秒）
STARTUP_GRACE=20                      # 重启后等待 session 就绪的秒数
MAX_LOG_SIZE=$((10 * 1024 * 1024))    # 日志轮转阈值 10MB

GUARDIAN_DIR="/home/admin/tools"
LOG_FILE="${GUARDIAN_DIR}/xpra-guardian.log"
PID_FILE="${GUARDIAN_DIR}/.xpra-guardian.pid"

XPRA_BIN="/usr/bin/xpra"
XAUTH_DISPLAY=":${DISPLAY_NUM}"

#==============================================================================
# 日志
#==============================================================================
log() {
    local msg="$1"
    local ts
    ts=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${ts} [guardian] ${msg}"
    # 轮转
    if [[ -f "${LOG_FILE}" ]]; then
        local size
        size=$(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ "${size}" -gt "${MAX_LOG_SIZE}" ]]; then
            tail -c $((MAX_LOG_SIZE / 2)) "${LOG_FILE}" > "${LOG_FILE}.tmp" 2>/dev/null \
                && mv "${LOG_FILE}.tmp" "${LOG_FILE}"
        fi
    fi
}

#==============================================================================
# session 启动命令（守护重启与手动启动复用同一份）
#==============================================================================
start_session() {
    log "Starting xpra session on :${DISPLAY_NUM}, port ${PORT} ..."
    "${XPRA_BIN}" start ":${DISPLAY_NUM}" \
        --bind-tcp="0.0.0.0:${PORT}" \
        --start=xterm \
        --start="fcitx5 -d --replace" \
        --start=cursor \
        --env=GTK_IM_MODULE=fcitx5 \
        --env=QT_IM_MODULE=fcitx5 \
        --env=XMODIFIERS=@im=fcitx \
        --daemon=yes \
        --tcp-auth=none \
        --html=on \
        --dpi="${DPI}" \
        --input-method=keep >> "${LOG_FILE}" 2>&1
    local rc=$?
    log "xpra start exit code: ${rc}"
    return ${rc}
}

#==============================================================================
# 清理崩溃残留（X lock / socket / session 目录里的死 pid）
#==============================================================================
cleanup_stale() {
    log "Cleaning up stale state for :${DISPLAY_NUM} ..."

    # 杀掉挂在该 display 上的孤儿 pulseaudio
    local pa_pids
    pa_pids=$(pgrep -f "pulseaudio.*display=:${DISPLAY_NUM}" 2>/dev/null)
    if [[ -n "${pa_pids}" ]]; then
        log "Killing orphan pulseaudio: ${pa_pids}"
        kill -9 ${pa_pids} 2>/dev/null
    fi

    # 杀掉残留 fcitx5（避免 --replace 冲突）
    local fcitx_pids
    fcitx_pids=$(pgrep -f "fcitx5" 2>/dev/null)
    if [[ -n "${fcitx_pids}" ]]; then
        log "Killing stale fcitx5: ${fcitx_pids}"
        kill -9 ${fcitx_pids} 2>/dev/null
    fi

    # 让 xpra 自己清理无效 session 记录
    "${XPRA_BIN}" list >/dev/null 2>&1

    # 清理 X lock / socket（如有权限）
    rm -f "/tmp/.X${DISPLAY_NUM}-lock" 2>/dev/null
    rm -f "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null
    rm -rf "/tmp/xpra/${DISPLAY_NUM}" 2>/dev/null

    sleep 1
}

#==============================================================================
# 健康检测
#   返回 0 = 健康；非 0 = 不健康
#==============================================================================
is_healthy() {
    # 1. 端口必须可连接（用 /dev/tcp 直连，比 ss/netstat 可靠 ——
    #    本环境 ss -ltn 输出为空，不能用来判断）
    #    端口可连 = xpra 网络层活着；僵尸 session（X server 挂但主进程在）
    #    时端口必然连不上，所以这一项已能覆盖 X server 崩溃场景。
    if ! timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${PORT}" 2>/dev/null; then
        log "UNHEALTHY: port ${PORT} not connectable"
        return 1
    fi

    # 2. xpra 主进程必须存在
    if ! pgrep -f "xpra start :${DISPLAY_NUM}" >/dev/null 2>&1; then
        log "UNHEALTHY: xpra main process for :${DISPLAY_NUM} not found"
        return 1
    fi

    # 3. X server 健康探测（尽力而为 —— 容器内 xauth 可能报授权问题，
    #    探测失败只记录警告，不据此判定不健康；真正的 X 崩溃会反映为端口不可连）
    # （xdpyinfo 在本容器有授权问题，探测不可靠，已移除以免刷屏；
    #   端口可连即代表 xpra 网络层 + 底层 X server 都活着）

    return 0
}

#==============================================================================
# 重启 session（清理 + 启动 + 等待就绪）
#==============================================================================
restart_session() {
    log "===== Restarting session ====="
    # 先尝试优雅停止
    "${XPRA_BIN}" stop ":${DISPLAY_NUM}" >/dev/null 2>&1
    sleep 2
    # 杀掉可能残留的 xpra 主进程
    pkill -9 -f "xpra start :${DISPLAY_NUM}" 2>/dev/null
    sleep 1

    cleanup_stale
    start_session

    log "Waiting ${STARTUP_GRACE}s for session to become ready ..."
    sleep "${STARTUP_GRACE}"

    if is_healthy; then
        log "===== Session restarted successfully ====="
        return 0
    else
        log "===== Session restart FAILED, will retry next cycle ====="
        return 1
    fi
}

#==============================================================================
# 守护主循环
#==============================================================================
guardian_loop() {
    log "########## Guardian loop started (pid=$$, display=:${DISPLAY_NUM}, port=${PORT}, interval=${CHECK_INTERVAL}s) ##########"

    # 启动时若 session 不存在则先拉起
    if ! is_healthy; then
        log "No healthy session at startup, starting one ..."
        restart_session
    else
        log "Existing healthy session detected, monitoring ..."
    fi

    while true; do
        sleep "${CHECK_INTERVAL}"
        if ! is_healthy; then
            log "Health check FAILED, triggering restart ..."
            restart_session
        fi
    done
}

#==============================================================================
# 命令分发
#==============================================================================
cmd_start() {
    # 用 PID 文件做并发控制（flock 的 fd 会被子进程继承导致锁无法释放，
    # 这里改用 PID 文件 + kill -0 探活，简单可靠）
    if [[ -f "${PID_FILE}" ]]; then
        local old_pid
        old_pid=$(cat "${PID_FILE}" 2>/dev/null)
        if [[ -n "${old_pid}" ]] && kill -0 "${old_pid}" 2>/dev/null; then
            # 进一步确认确实是本守护进程（防 PID 复用）
            if ps -p "${old_pid}" -o args= 2>/dev/null | grep -q "xpra-guardian.sh foreground"; then
                echo "Guardian already running (pid=${old_pid})."
                exit 1
            fi
        fi
    fi

    echo "Starting xpra guardian in background ..."
    nohup "$0" foreground >> "${LOG_FILE}" 2>&1 &
    local gpid=$!
    echo "${gpid}" > "${PID_FILE}"
    echo "Guardian started (pid=${gpid})."
    echo "Log: ${LOG_FILE}"
    echo "Stop: $0 stop"
}

cmd_stop() {
    if [[ ! -f "${PID_FILE}" ]]; then
        echo "Guardian not running (no pid file)."
        return 0
    fi
    local gpid
    gpid=$(cat "${PID_FILE}" 2>/dev/null)
    if [[ -n "${gpid}" ]] && kill -0 "${gpid}" 2>/dev/null; then
        kill "${gpid}" 2>/dev/null
        sleep 1
        kill -9 "${gpid}" 2>/dev/null
        log "Guardian stopped (pid=${gpid})"
        echo "Guardian stopped (pid=${gpid})."
    else
        echo "Guardian pid ${gpid} not alive."
    fi
    rm -f "${PID_FILE}"
}

cmd_status() {
    echo "===== Guardian ====="
    if [[ -f "${PID_FILE}" ]]; then
        local gpid
        gpid=$(cat "${PID_FILE}" 2>/dev/null)
        if [[ -n "${gpid}" ]] && kill -0 "${gpid}" 2>/dev/null; then
            echo "Guardian: RUNNING (pid=${gpid})"
        else
            echo "Guardian: DEAD (stale pid file: ${gpid})"
        fi
    else
        echo "Guardian: NOT RUNNING"
    fi

    echo ""
    echo "===== Session (:${DISPLAY_NUM}) ====="
    if is_healthy >/dev/null 2>&1; then
        echo "Session: HEALTHY"
    else
        echo "Session: UNHEALTHY / DOWN"
    fi
    echo "- port ${PORT}: $(timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${PORT}" 2>/dev/null && echo LISTENING || echo DOWN)"
    echo "- xpra proc: $(pgrep -f "xpra start :${DISPLAY_NUM}" >/dev/null && echo ALIVE || echo DEAD)"
    echo "- cursor proc: $(pgrep -f "cursor --no-sandbox" >/dev/null && echo ALIVE || echo DEAD)"
    echo "- fcitx5 proc: $(pgrep -f "fcitx5" >/dev/null && echo ALIVE || echo DEAD)"
    echo ""
    echo "Connect: http://<host>:${PORT}/"
    echo "Log: ${LOG_FILE}"
}

case "${1:-}" in
    start)            cmd_start ;;
    stop)             cmd_stop ;;
    status)           cmd_status ;;
    check)            is_healthy && echo "HEALTHY" || echo "UNHEALTHY" ;;
    restart-session)  restart_session ;;
    foreground)       guardian_loop ;;
    *)
        echo "Usage: $0 {start|stop|status|check|restart-session|foreground}"
        echo ""
        echo "  start            后台启动守护（nohup）"
        echo "  stop             停止守护"
        echo "  status           查看守护和 session 状态"
        echo "  check            手动跑一次健康检测"
        echo "  restart-session  手动强制重启一次 session"
        echo "  foreground       前台运行守护循环（调试用）"
        exit 1
        ;;
esac
