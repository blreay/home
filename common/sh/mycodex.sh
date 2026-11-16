#!/bin/bash
###############################################
# 一键更新/修复 @openai/codex CLI: 卸载 -> 重装 -> 验证
# 背景: codex 的平台二进制包 (@openai/codex-linux-x64 等,
#       是 npm:@openai/codex@<ver>-<os>-<arch> 的 alias optional dep)
#       下载失败时 npm 把 optionalDependencies 静默跳过, 退出码仍是 0,
#       日志只有 "changed N packages in Ns", npm ls 显示全部
#       UNMET OPTIONAL DEPENDENCY。运行时爆
#       "Missing optional dependency @openai/codex-linux-x64"。
#       因此不能用 npm 退出码判断成功, 必须以「本次 npm prefix 下的
#       codex --version」为准(PATH 上可能是另一份 /usr/bin/codex)。
#       平台包被跳过时再按非 optional 显式安装, 把被吞掉的下载错误打出来。
#       https_proxy 指向无法解析的代理时, npm 直连 registry。
#       先卸载保证全新安装树。
#       还有一个坑: codex 自身的升级检查硬编码对照官方 registry.npmjs.org,
#       而内部镜像 registry.anpm.alibaba-inc.com 对 @openai/codex 开了 24h
#       延迟可用 hold(delayed-availability buffer, holdDuration=1440m):
#       新版本发布后 24h 内镜像 latest 不动、显式版本号和 tarball 均 404。
#       于是从镜像装 @latest 永远"成功"装到旧版(npm 退出码 0, codex 也能跑),
#       但 codex 仍提示升级; 装官方新版号则 404 —— 即「升级总是失败,
#       脚本报成功却仍提示升级」的根因。因此本脚本以官方源 latest 为目标
#       版本: 镜像有该版本走镜像(内网快), 没有则直连官方源安装(绕过镜像
#       24h 供应链防护窗口, 会明确告警); 且成功标准从「codex 能跑」收紧为
#       「codex 能跑且版本==目标版本」。
###############################################

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mycommon.sh"

typeset -a g_mandatory_utilities=(npm node)
typeset g_pkg="@openai/codex"
typeset g_install_max_retry=3
typeset g_npm_drop_proxy=0
## codex 升级检查对照的官方源; 内部镜像 24h hold 未放出新版本时直连它
typeset g_official_registry="https://registry.npmjs.org"
## 查询类 npm 命令的防挂死参数(无外网时快速失败)
typeset g_npm_view_opts="--fetch-retries=1 --fetch-timeout=30000"

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

## 当前环境里的代理 URL, 都没有则空
function my_proxy_url {
    echo "${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-}}}}"
}

## 代理主机无法解析时, 后续 npm 去掉代理环境变量直连。返回 0 表示已切换。
function my_drop_dead_proxy {
    typeset proxy_url=""
    typeset proxy_host=""

    [[ ${g_npm_drop_proxy} -eq 1 ]] && return 1
    proxy_url="$(my_proxy_url)"
    [[ -z "${proxy_url}" ]] && return 1
    if ! type getent >/dev/null 2>&1; then
        WARN "没有 getent, 跳过代理解析检查"
        return 1
    fi

    proxy_host="${proxy_url#*://}"
    proxy_host="${proxy_host%%/*}"
    proxy_host="${proxy_host%%:*}"
    proxy_host="${proxy_host#*@}"
    [[ -z "${proxy_host}" ]] && return 1
    if getent hosts "${proxy_host}" >/dev/null 2>&1; then
        return 1
    fi
    WARN "代理 ${proxy_url} 无法解析, npm 改为直连 registry"
    g_npm_drop_proxy=1
    return 0
}

## g_npm_drop_proxy=1 时不把失效代理传给 npm
function my_npm {
    if [[ ${g_npm_drop_proxy} -eq 1 ]]; then
        (
            unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy FTP_PROXY all_proxy ALL_PROXY
            npm "$@"
        )
    else
        npm "$@"
    fi
}

## 只认本次 global prefix 里的 codex, 避免 PATH 上的 /usr/bin/codex 假成功
function my_codex_bin {
    echo "$(npm prefix -g)/bin/codex"
}

## 当前 prefix 下 codex --version 的完整输出, 不可执行/跑失败返回非 0
function my_codex_ver {
    typeset bin=""
    bin="$(my_codex_bin)"
    [[ -x "${bin}" ]] || return 1
    "${bin}" --version 2>/dev/null
}

## 纯版本号, 如 0.169.0(取 --version 输出最后一个字段)
function my_codex_vernum {
    typeset out=""
    out="$(my_codex_ver)" || return 1
    echo "${out##* }"
}

## codex 可运行; expect 非空且非 latest 时还要求版本号一致,
## 防止镜像滞后时「@latest 装上的其实是旧版」的假成功
function my_codex_ok {
    typeset expect="${1:-}" got=""
    got="$(my_codex_ver)" || return 1
    echo "${got}"
    [[ -z "${expect}" || "${expect}" == "latest" ]] && return 0
    if [[ "${got##* }" != "${expect}" ]]; then
        WARN "$(my_codex_bin) 版本 ${got##* } != 目标 ${expect}"
        return 1
    fi
    return 0
}

## 指定 registry(缺省当前 npm 配置源)上 g_pkg 的 latest 版本号, 查不到返回非 0
function my_registry_latest {
    typeset reg="${1:-}" regopt="" out=""
    [[ -n "${reg}" ]] && regopt="--registry=${reg}"
    out="$(my_npm view "${g_pkg}" version ${regopt} ${g_npm_view_opts} 2>/dev/null | tail -1)"
    [[ "${out}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    echo "${out}"
}

## 指定版本在指定 registry(缺省当前配置源)上是否可安装
function my_registry_has_version {
    typeset ver="${1}" reg="${2:-}" regopt=""
    [[ -n "${reg}" ]] && regopt="--registry=${reg}"
    my_npm view "${g_pkg}@${ver}" version ${regopt} ${g_npm_view_opts} >/dev/null 2>&1
}

## optional 平台包被 npm 静默跳过时, 按普通依赖再装一次, 失败会露出真实错误
## $2: 传给 npm 的 --registry=... (可空, 与主包安装用同一个源)
function my_install_platform {
    typeset plat="${1}"
    typeset regopt="${2:-}"
    typeset codex_dir=""
    typeset ver=""
    typeset plat_tag=""
    typeset alias_spec=""

    codex_dir="$(npm root -g)/${g_pkg}"
    [[ -f "${codex_dir}/package.json" ]]
    BCS_CHK_RC0 "找不到 ${codex_dir}/package.json, 主包没有装上"

    ver="$(node -p "require('${codex_dir}/package.json').version")"
    BCS_CHK_RC0 "读不到 ${g_pkg} 版本号"
    plat_tag="${plat#@openai/codex-}"
    alias_spec="${plat}@npm:${g_pkg}@${ver}-${plat_tag}"
    MSG "显式安装平台包: ${alias_spec}"
    my_npm install --prefix "${codex_dir}" --no-save --no-package-lock --prefer-online ${regopt} "${alias_spec}"
    BCS_CHK_RC0 "显式安装 ${plat} 失败"
    return 0
}

######## write your own logic #####################
function my_entry {
    typeset version="${1:-latest}"
    typeset pkg_ver=""
    typeset plat=""
    typeset i=
    typeset rc=0
    typeset ok=0
    typeset official_latest="" mirror_latest="" target_ver="" regopt="" reg_desc=""

    ## 防止误把错误 flag 等当成版本号
    [[ "${version}" == "latest" || "${version}" =~ ^[0-9]+\.[0-9]+ ]]
    BCS_CHK_RC0 "非法版本号 [${version}], 应为 latest 或形如 0.55.0 的版本号"

    plat=$(my_platform_pkg "$(uname -s)" "$(uname -m)")
    BCS_CHK_RC0 "无法识别本机平台 $(uname -s)/$(uname -m), codex 只提供 linux/darwin/win32 的 x64/arm64 包"

    my_drop_dead_proxy || true

    ## 目标版本以官方源 latest 为准: codex 的升级检查对照官方源,
    ## 镜像 latest 在 24h hold 期间会滞后, 装镜像 latest 会「成功」却仍提示升级
    official_latest="$(my_registry_latest "${g_official_registry}")" \
        || WARN "查不到官方源 ${g_official_registry} 的 ${g_pkg} latest(无外网?), 回退用配置源"
    mirror_latest="$(my_registry_latest)" || true
    target_ver="${version}"
    if [[ "${version}" == "latest" ]]; then
        target_ver="${official_latest:-${mirror_latest:-latest}}"
    fi

    ## 选安装源: 配置源上有目标版本就走它(内网快), 没有(镜像 24h hold 未放出)则直连官方源
    if [[ "${target_ver}" == "latest" ]] || my_registry_has_version "${target_ver}"; then
        reg_desc="$(npm config get registry)"
    else
        regopt="--registry=${g_official_registry}"
        reg_desc="${g_official_registry}"
        WARN "配置源 $(npm config get registry) 上没有 ${target_ver}(内部镜像对新版本有 24h hold), 直连官方源安装"
        WARN "注意: 直连官方源会绕过镜像的供应链防护窗口, 且大包下载较慢(可能数分钟到数十分钟)"
    fi
    pkg_ver="${g_pkg}@${target_ver}"

    MSG "== 1/4 安装前检查 =="
    MSG "配置源      : $(npm config get registry) (latest: ${mirror_latest:-未知})"
    MSG "官方源      : ${g_official_registry} (latest: ${official_latest:-未知}, codex 升级检查对照此源)"
    MSG "本次安装源  : ${reg_desc}"
    MSG "npm root -g  : $(npm root -g)"
    MSG "平台二进制包 : ${plat}"
    MSG "npm proxy    : $(my_proxy_url)"
    MSG "验证命令    : $(my_codex_bin) --version"
    if [[ -x "$(my_codex_bin)" ]]; then
        my_codex_ok
        BCS_WARN_RC0 "当前 $(my_codex_bin) 不可用(首次安装可忽略)"
    else
        WARN "当前尚未安装 $(my_codex_bin)(首次安装可忽略)"
    fi
    MSG "准备安装    : ${pkg_ver} (以 $(my_codex_bin) 版本号==${target_ver} 为准, 最多 ${g_install_max_retry} 次)"

    MSG "== 2/4 卸载旧的 ${g_pkg} (保证全新安装树, 清掉可能残留的空目录) =="
    my_npm uninstall -g "${g_pkg}"
    BCS_CHK_RC0 "卸载 ${g_pkg} 失败"

    MSG "== 3/4 安装 ${pkg_ver} =="
    i=1
    while [[ ${i} -le ${g_install_max_retry} ]]; do
        MSG "-- 第 ${i}/${g_install_max_retry} 次尝试"
        my_npm install -g ${regopt} "${pkg_ver}"
        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            WARN "npm install 失败 RET=${rc}"
        elif my_codex_ok "${target_ver}"; then
            ok=1
            break
        else
            ## npm 对 optionalDependencies 失败不报错, 退出码仍为 0
            WARN "npm 退出码 0, 但 ${plat} 未装上或版本不符(optional dependency 被静默跳过)"
            npm ls -g --depth=1 "${g_pkg}" 2>&1 | head -20 || true
            my_install_platform "${plat}" "${regopt}"
            rc=$?
            if [[ ${rc} -eq 0 ]] && my_codex_ok "${target_ver}"; then
                ok=1
                break
            fi
            WARN "显式安装 ${plat} 后仍不可用 RET=${rc}"
        fi
        [[ ${i} -lt ${g_install_max_retry} ]] && {
            MSG "等待 5 秒后重试"
            sleep 5
        }
        i=$((i+1))
    done

    ## 直连官方源全部失败时退回镜像上可用的版本, 避免卸载后装不回(旧版, codex 仍会提示升级)
    if [[ ${ok} -ne 1 && -n "${regopt}" && -n "${mirror_latest}" ]]; then
        WARN "直连官方源安装失败, 回退安装配置源可用版本 ${mirror_latest}"
        if my_npm install -g "${g_pkg}@${mirror_latest}" && my_codex_ok "${mirror_latest}"; then
            ok=1
            WARN "当前为旧版 ${mirror_latest}, 待镜像 24h hold 放出后可再升级到 ${target_ver}"
        fi
    fi

    [[ ${ok} -eq 1 ]]
    BCS_CHK_RC0 "重试 ${g_install_max_retry} 次后 ${plat} 仍不可用, 请检查网络或 npm registry"

    MSG "== 4/4 安装完成 =="
    MSG "已装版本: $(my_codex_vernum) (目标 ${target_ver}, 官方 latest ${official_latest:-未知})"
    return 0
}

###########################################
main ${@:+"$@"}