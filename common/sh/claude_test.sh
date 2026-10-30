#!/bin/bash
#
# claude_test.sh -- 查询一个模型或所有 aone 模型的可用性(并行查询)
#
# 用法:
#   claude_test.sh                 # 并行测试所有 aone 模型(来自 ducky quota/models 接口)
#   claude_test.sh -a              # 同上, 显式指定
#   claude_test.sh -l              # 只列出模型名, 不测试
#   claude_test.sh <model> ...     # 并行测试指定的一个或多个模型
#   claude_test.sh -L [-i 间隔] <model,...>   # 循环探测模式(死循环, 不依赖crontab)
#
# 循环探测模式(-L):
#   -i 指定探测间隔, 支持 s/m/h 后缀(如 -i 30m / -i 1h), 默认 1800 秒;
#   模型名可用逗号分隔指定多个(如 m1,m2), 不指定时默认 claude-opus-5-5;
#   通知规则(通过 myc_dingding.sh 发钉钉, 可用环境变量 NOTIFY_CMD 覆盖):
#     探测成功       -> 每次都通知;
#     可用变为不可用 -> 通知一次;
#     持续不可用     -> 不再重复通知;
#   后台运行示例:
#     nohup claude_test.sh -L -i 30m claude-opus-5-5 >watch.log 2>&1 &
#
# 依赖: 环境变量 ANTHROPIC_AUTH_TOKEN (查询模型列表用)
#
# 退出码: 全部可用为 0, 否则为不可用模型的个数
#

MODELS_URL=${MODELS_URL:-https://ducky.code.alibaba-inc.com/v1/quota/models}
# 循环探测模式的通知命令(消息作为其参数)
NOTIFY_CMD=${NOTIFY_CMD:-myc_dingding.sh}
# 循环探测模式的默认模型与间隔(秒)
WATCH_DEFAULT_MODEL=${WATCH_DEFAULT_MODEL:-claude-opus-5-5}
WATCH_DEFAULT_INTERVAL=${WATCH_DEFAULT_INTERVAL:-1800}

# 获取所有模型名: ducky quota 接口返回 JSON 数组, 取 model_id 字段
function get_models {
	[[ -z ${ANTHROPIC_AUTH_TOKEN:-} ]] && {
		echo "ERR: ANTHROPIC_AUTH_TOKEN is not set" >&2
		return 1
	}
	curl -s "$MODELS_URL" -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" |
		jq -r '.[].model_id' 2>/dev/null
}

# 测试单个模型(详细输出), 兼容原有行为
function test_one {
	typeset model=${1:-claude-opus-5-5}
	CMD=$(cat - <<EOF
claude_test.py --model ${model} -p --output-format stream-json --verbose --bare "hi"
EOF
)
	echo "$CMD"
	$CMD &>/dev/null
	typeset ret=$?
	echo "ret=$ret"
	[[ $ret -eq 0 ]] && echo "OK" || echo "NG"
	return $ret
}

# 静默测试单个模型, 只返回退出码(用于并行)
function test_one_quiet {
	typeset model=$1
	claude_test.py --model "$model" -p --output-format stream-json --verbose --bare "hi" &>/dev/null
	return $?
}

# 并行测试一组模型, 打印汇总表
function test_models {
	typeset -a models=("$@")
	[[ ${#models[@]} -eq 0 ]] && { echo "no models to test" >&2; return 1; }

	# 单个模型时保留详细输出
	if [[ ${#models[@]} -eq 1 ]]; then
		test_one "${models[0]}"
		return $?
	fi

	typeset tmpdir
	tmpdir=$(mktemp -d /tmp/claude_test.XXXXXX) || return 1
	trap 'rm -rf "$tmpdir"' RETURN

	echo "testing ${#models[@]} models in parallel ..."
	typeset m
	for m in "${models[@]}"; do
		(
			test_one_quiet "$m"
			echo $? >"$tmpdir/$m.rc"
		) &
	done
	wait

	typeset -i ng=0
	echo "----------------------------------------"
	for m in "${models[@]}"; do
		typeset rc
		rc=$(cat "$tmpdir/$m.rc" 2>/dev/null)
		rc=${rc:-ERR}
		if [[ $rc -eq 0 ]]; then
			printf '%-24s %s\n' "$m" "OK"
		else
			printf '%-24s %s\n' "$m" "NG (ret=$rc)"
			ng+=1
		fi
	done
	echo "----------------------------------------"
	echo "total=${#models[@]} ok=$((${#models[@]} - ng)) ng=$ng"
	return $ng
}

# 发通知(默认走 myc_dingding.sh 钉钉机器人)
function notify {
	typeset msg="$*"
	echo "[$(date '+%F %T')] [notify] $msg"
	typeset cmd=${NOTIFY_CMD%% *}
	if command -v "$cmd" &>/dev/null; then
		${NOTIFY_CMD} "$msg" &>/dev/null || echo "WARN: notify command failed: ${NOTIFY_CMD}" >&2
	else
		echo "WARN: $cmd not found in PATH, skip notify" >&2
	fi
}

# 解析间隔参数: 纯数字为秒, 支持 s/m/h 后缀, 如 300 / 30m / 1h
function parse_interval {
	typeset spec=${1:-$WATCH_DEFAULT_INTERVAL}
	typeset num=${spec%[smh]}
	typeset unit=${spec#"$num"}
	if [[ ! $num =~ ^[0-9]+$ || $num -eq 0 ]]; then
		echo "ERR: bad interval: $spec (示例: 300, 30m, 1h)" >&2
		return 1
	fi
	case $unit in
		''|s) echo "$num" ;;
		m) echo $((num * 60)) ;;
		h) echo $((num * 3600)) ;;
		*) echo "ERR: bad interval unit: $spec (支持 s/m/h)" >&2; return 1 ;;
	esac
}

# 循环探测模式: 每隔 interval 秒探测一遍所有模型
# 成功每次都通知; OK->NG 变化时通知一次; 持续 NG 不重复通知
function watch_models {
	typeset interval=$1; shift
	typeset -a models=("$@")
	typeset -A prev_state
	echo "watch mode: models=[${models[*]}] interval=${interval}s notify=[${NOTIFY_CMD}]"
	typeset m rc st spid
	while true; do
		for m in "${models[@]}"; do
			test_one_quiet "$m"; rc=$?
			[[ $rc -eq 0 ]] && st=OK || st=NG
			echo "[$(date '+%F %T')] $m: $st (ret=$rc)"
			if [[ $st == OK ]]; then
				notify "claude_test: 模型 [$m] 可用 (OK)"
			elif [[ ${prev_state[$m]:-} == OK ]]; then
				notify "claude_test: 模型 [$m] 变为不可用 (NG, ret=$rc)"
			fi
			prev_state[$m]=$st
		done
		# 后台 sleep + wait, 保证 INT/TERM 能立即退出
		sleep "$interval" &
		spid=$!
		trap 'kill $spid 2>/dev/null; echo; echo "[$(date "+%F %T")] watch stopped"; exit 0' INT TERM
		wait $spid 2>/dev/null
	done
}

function my_show_usage {
	# 打印文件头部注释块(第3行起连续的 # 注释行)
	awk 'NR>=3 && /^#/ {sub(/^# ?/, ""); print; next} NR>=3 {exit}' "$0"
}

# 把逗号/空格分隔的模型参数展开成数组
function split_models {
	typeset -a out=()
	typeset arg
	for arg in "$@"; do
		typeset IFS=', '
		read -ra _parts <<< "$arg"
		typeset p
		for p in "${_parts[@]}"; do
			[[ -n $p ]] && out+=("$p")
		done
	done
	printf '%s\n' "${out[@]}"
}

function main {
	typeset -a models=()
	typeset list_only=0 all=0 watch=0
	typeset interval=$WATCH_DEFAULT_INTERVAL
	while getopts "alhwi:L" opt; do
		case $opt in
			a) all=1 ;;
			l) list_only=1 ;;
			L) watch=1 ;;
			i) interval=$(parse_interval "$OPTARG") || return 1 ;;
			w) : ;; # 已废弃: 模型列表不再依赖 workspace
			h) my_show_usage; return 0 ;;
			*) my_show_usage; return 1 ;;
		esac
	done
	shift $((OPTIND - 1))

	if [[ $list_only -eq 1 ]]; then
		get_models
		return 0
	fi

	if [[ $# -gt 0 ]]; then
		mapfile -t models < <(split_models "$@")
	fi

	# 循环探测模式: 不指定模型时用默认模型, 不去拉全量列表
	if [[ $watch -eq 1 ]]; then
		[[ ${#models[@]} -eq 0 ]] && models=("$WATCH_DEFAULT_MODEL")
		watch_models "$interval" "${models[@]}"
		return $?
	fi

	if [[ ${#models[@]} -eq 0 ]]; then
		mapfile -t models < <(get_models)
		[[ ${#models[@]} -eq 0 ]] && {
			echo "ERR: get models failed (url=$MODELS_URL)" >&2
			return 1
		}
	fi

	test_models "${models[@]}"
}

# 直接执行时进入 main; 被 source 时只加载函数(兼容原用法)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
	exit $?
fi
