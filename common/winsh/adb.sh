#!/bin/bash

## pipefail: the return value of a pipeline is the status of the last command to exit 
## with a non-zero status, or zero if no command exited with a non-zero status
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo

####################################################### 
#typeset g_chname="orderer0"
typeset g_chname="default"
typeset g_user="admin"
typeset g_yyb_app="com.tencent.android.qqdownloader/com.tencent.assistantv2.activity.MainActivity"

#######################################################
alias BCS_CHK_RC0='{ 
	#### function check RC Block Begin #####
	RET=$?
	if [[ ${RET} -ne 0 ]]; then
		MSG=$(cat -)
		ERR "${MSG}, RET=${RET}"
		[[ -n "${g_configtxlator_pid}" ]] && kill -9 ${g_configtxlator_pid} && LOG "kill configtxlator pid=${g_configtxlator_pid} OK"
		return "${RET}"
	fi
	#### function check RC Block End #####
}<<<'

function gen_mark_line { 
	ch=$1
	len=$2
	printf "%s\n" "$(eval printf "$ch%.0s" {1..${len}})"
}

function DBG {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
	printf "%s" "${msg}" >&2
	return 0
} 
function MSG {
	typeset arg="${@}"
	typeset msg
	printf -v msg "%s\n" "${arg}"
	printf "%s" "${msg}" >&1
	return 0
} 
function LOG {
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
	printf "%s" "${msg}"
	return 0
} 

function ERR {
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}"
	printf "%s" "${msg}"
	return 0
} 

function adbsudo {
	 CMD="adb shell su root $@"
	 DBG "${CMD}"
	 eval ${CMD}
}
function adbreboot {
	 CMD="adb shell su root reboot"
	 MSG "${CMD}"
	 eval ${CMD}
}
function startapp {
	CMD="adb shell am start $1  | sed '/WARNING: linker/d'"
	echo "${CMD}"
	eval "${CMD}"
} 
function stopapp {
	pkgname=${1%/*}
	adb shell am force-stop $pkgname
	adb shell am kill $pkgname
}
function testnet {
	adb shell ping -c 3 www.baidu.com
}
#####################################################################
## Main
function main { 
	#set -vx
	unset OPTIND
	while getopts :dFP:S name; do
		case $name in
		p) lport=$OPTARG; echo "aa" ;;
		f) force=1; echo force;;
		d) export MYDBG=DEBUG;;
		*) echo "wrong parameter: $name";exit 1; ;;
		esac
	done 
	DBG "\$@=$@"
	shift $((${OPTIND}-1))
	act=$1
	DBG "act=${act}"
	shift 1
	case "${act}" in
	r|reboot)    adbreoot;;
	y|yyb)       startapp "${g_yyb_app}";;
	s|sudo)      adbsudo "${@}";;
	ss|busybox)  adbsudo busybox "${@}";;
	""|devices)  adb devices;;
	*)           adbsudo "${act}" "${@}";;
	esac
} 
#####################################################################
main "${@}"
