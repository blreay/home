#!/bin/bash
###############################################
# 一键更新/修复 @openai/codex CLI: 卸载 -> 重装 -> 验证
# 背景: codex 的平台二进制包 (@openai/codex-linux-x64 等,
#       是 npm:@openai/codex@<ver>-<os>-<arch> 的 alias optional dep)
#       下载失败时 npm 把 optionalDependencies 静默跳过, 退出码仍是 0,
#       日志只有 "changed N packages in Ns", npm ls 显示全部
#       UNMET OPTIONAL DEPENDENCY。运行时爆
#       "Missing optional dependency @openai/codex-linux-x64"。
#       因此不能用 npm 退出码判断成功, 必须以 codex --version 为准并重试。
#       先卸载保证全新安装树。
###############################################

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mycommon.sh"

typeset -a g_mandatory_utilities=(npm)
typeset g_pkg="@openai/codex"
typeset g_install_max_retry=3

function my_show_usage {
    cat - <<EOF
Usage[Basic]: ${g_appname_short} [version]
    version : 要安装的版本号(如 0.55.0), 缺省 latest
功能: 先卸载旧的 ${g_pkg} 再重新安装并实际运行验证
Example:
    ${g_appname_short}              # 更新到最新版
    ${g_appname_short} 0.55.0      # 安装指定版本
EOF
}

## 本机对应的 optional 平台包名, 与 codex.js 的 PLATFORM_PACKAGE_BY_TARGET 一致
function my_platform_pkg {
    typeset os="${1}"
    typeset arch="${2}"
    typeset oskey=""
    typeset archkey=""

    case "${os}" in
        Linux) oskey="linux" ;;
        Darwin) oskey="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) oskey="win32" ;;
        *) return 1 ;;
    esac
    case "${arch}" in
        x86_64|amd64) archkey="x64" ;;
        aarch64|arm64) archkey="arm64" ;;
        *) return 1 ;;
    esac
    echo "@openai/codex-${oskey}-${archkey}"
    return 0
}

######## write your own logic #####################
function my_entry {
    typeset version="${1:-latest}"
    typeset pkg_ver="${g_pkg}@${version}"
    typeset plat=""
    typeset i=
    typeset rc=0
    typeset ok=0

    ## 防止误把错误 flag 等当成版本号
    [[ "${version}" == "latest" || "${version}" =~ ^[0-9]+\.[0-9]+ ]]
    BCS_CHK_RC0 "非法版本号 [${version}], 应为 latest 或形如 0.55.0 的版本号"

    plat=$(my_platform_pkg "$(uname -s)" "$(uname -m)")
    BCS_CHK_RC0 "无法识别本机平台 $(uname -s)/$(uname -m), codex 只提供 linux/darwin/win32 的 x64/arm64 包"

    MSG "== 1/4 安装前检查 =="
    MSG "npm registry : $(npm config get registry)"
    MSG "npm root -g  : $(npm root -g)"
    MSG "平台二进制包 : ${plat}"
    codex --version
    BCS_WARN_RC0 "当前 codex 不可用或尚未安装(首次安装可忽略)"
    MSG "准备安装    : ${pkg_ver} (以 codex --version 为准, 最多 ${g_install_max_retry} 次)"

    MSG "== 2/4 卸载旧的 ${g_pkg} (保证全新安装树, 清掉可能残留的空目录) =="
    npm uninstall -g "${g_pkg}"
    BCS_CHK_RC0 "卸载 ${g_pkg} 失败"

    MSG "== 3/4 安装 ${pkg_ver} =="
    i=1
    while [[ ${i} -le ${g_install_max_retry} ]]; do
        MSG "-- 第 ${i}/${g_install_max_retry} 次尝试"
        npm install -g "${pkg_ver}"
        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            WARN "npm install 失败 RET=${rc}"
        elif codex --version; then
            ok=1
            break
        else
            ## npm 对 optionalDependencies 失败不报错, 退出码仍为 0
            WARN "npm 退出码 0, 但 ${plat} 未装上(optional dependency 被静默跳过)"
            npm ls -g --depth=1 "${g_pkg}" 2>&1 | head -20 || true
        fi
        [[ ${i} -lt ${g_install_max_retry} ]] && {
            MSG "等待 5 秒后重试"
            sleep 5
        }
        i=$((i+1))
    done
    [[ ${ok} -eq 1 ]]
    BCS_CHK_RC0 "重试 ${g_install_max_retry} 次后 ${plat} 仍不可用, 请检查网络或 npm registry"

    MSG "== 4/4 安装完成 =="
    return 0
}

###########################################
main ${@:+"$@"}