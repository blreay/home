#!/bin/bash
###############################################
# 一键更新/修复 @openai/codex CLI: 卸载 -> 重装 -> 验证
# 背景: codex 的平台二进制包 (@openai/codex-linux-x64 等,
#       是 npm:@openai/codex@<ver>-<os>-<arch> 的 alias optional dep)
#       更新时若下载超时会被 npm 静默跳过(optionalDependencies
#       失败不报错), 留下空目录, 运行时爆
#       "Missing optional dependency @openai/codex-linux-x64"。
#       先卸载保证全新安装树, 安装失败自动重试, 最后实际运行验证。
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

######## write your own logic #####################
function my_entry {
    typeset version="${1:-latest}"
    typeset pkg_ver="${g_pkg}@${version}"
    typeset i=
    typeset rc=0
    typeset ok=0

    ## 防止误把错误 flag 等当成版本号
    [[ "${version}" == "latest" || "${version}" =~ ^[0-9]+\.[0-9]+ ]]
    BCS_CHK_RC0 "非法版本号 [${version}], 应为 latest 或形如 0.55.0 的版本号"

    MSG "== 1/4 安装前检查 =="
    MSG "npm registry : $(npm config get registry)"
    MSG "npm root -g  : $(npm root -g)"
    codex --version
    BCS_WARN_RC0 "当前 codex 不可用或尚未安装(首次安装可忽略)"
    MSG "准备安装    : ${pkg_ver} (安装失败重试 ${g_install_max_retry} 次)"

    MSG "== 2/4 卸载旧的 ${g_pkg} (保证全新安装树, 清掉可能残留的空目录) =="
    npm uninstall -g "${g_pkg}"
    BCS_CHK_RC0 "卸载 ${g_pkg} 失败"

    MSG "== 3/4 安装 ${pkg_ver} =="
    i=1
    while [[ ${i} -le ${g_install_max_retry} ]]; do
        MSG "-- 第 ${i}/${g_install_max_retry} 次尝试"
        npm install -g "${pkg_ver}"
        rc=$?
        [[ ${rc} -eq 0 ]] && { ok=1; break; }
        WARN "npm install 失败 RET=${rc}, 等待 5 秒后重试"
        sleep 5
        i=$((i+1))
    done
    [[ ${ok} -eq 1 ]]
    BCS_CHK_RC0 "重试 ${g_install_max_retry} 次后安装 ${pkg_ver} 仍失败, 请检查网络或 npm registry"

    MSG "== 4/4 实际运行验证 =="
    codex --version
    BCS_CHK_RC0 "安装后 codex 仍无法运行, 平台二进制包(${g_pkg}-<os>-<arch>)可能又被跳过, 请重跑本脚本再试一次"

    return 0
}

###########################################
main ${@:+"$@"}