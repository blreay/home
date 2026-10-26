#!/bin/bash
#
# claude_test.sh -- 查询一个模型或所有 aone 模型的可用性(并行查询)
#
# 用法:
#   claude_test.sh                 # 并行测试所有 aone 模型(来自 a1 devix task models)
#   claude_test.sh -a              # 同上, 显式指定
#   claude_test.sh -l              # 只列出模型名, 不测试
#   claude_test.sh <model> ...     # 并行测试指定的一个或多个模型
#   claude_test.sh -w <workspace>  # 指定 workspace (默认 69737, 也可用环境变量 CLAUDE_TEST_WORKSPACE)
#
# 退出码: 全部可用为 0, 否则为不可用模型的个数
#

MYWORKSPACE=${CLAUDE_TEST_WORKSPACE:-69737}

# 获取所有模型名: 取 VALUE 列, 跳过表头和 "custom"(非真实模型)
function get_models {
	a1 devix task models --workspace "$MYWORKSPACE" 2>/dev/null |
		awk 'NR>1 && $1!="" && $1!="custom" {print $1}'
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

function my_show_usage {
	sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'
}

function main {
	typeset -a models=()
	typeset list_only=0 all=0
	while getopts "alhw:" opt; do
		case $opt in
			a) all=1 ;;
			l) list_only=1 ;;
			w) MYWORKSPACE=$OPTARG ;;
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
		models=("$@")
	else
		mapfile -t models < <(get_models)
		[[ ${#models[@]} -eq 0 ]] && {
			echo "ERR: get models failed (workspace=$MYWORKSPACE)" >&2
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
