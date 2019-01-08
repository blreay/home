#!/bin/bash

###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo

typeset g_appname
typeset PS_OPT_LONG="uname pid ppid start_time etime time command"
#typeset PS_OPT_SHORT="uname pid ppid start_time etime time comm"
############################################## 
function DBG {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}" >&2
} 
function LOG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
} 
function ERR {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}" >&2
} 
############################################## 
typeset g_appname

typeset arywineps=(
wineserver
winedevice.exe
winecfg.exe
winedbg
wineboot.exe
winemenubuilder.exe
WeChat.exe
services.exe
plugplay.exe
explorer.exe
aQQ.exe
aaaaweixin_multi.exe
tencentdl.exe
QQSetupEx.exe
QQProtect.exe
"\.exe "
".exe$"
"\.EXE "
)

function usage {
	showerr "Usage: ${g_appname##*/} [-d] [ps [long]|kill]"
    showerr "   command : ps kill "
    showerr "        -d : enable debug mode"
}


function showerr {
	echo ${@:+"$@"} >&2
}

function cvs_add_one_folder {
	typeset dirname="$1"
}

############################################################
function main {

	############################################
	export g_apppath=${0}
	export g_appname=${0##*/}
	[[ ${g_appname} == "bash" ]] && export g_apppath=`pwd`/
	# set debug
	unset OPTIND
	while getopts :s:p:dh ch; do
		DBG "ch=$ch"
		case $ch in
		"d") export MYDBG=DEBUG;;
		"h") usage; return 0;;
		*) echo "wrong parameter $ch"; return 1;;
		esac
	done
	shift $((OPTIND-1))
	DBG "g_appname=$g_appname"
	DBG "g_apppath=$g_apppath"
	DBG "\$@=$@"
	############################################

strorig="${@}"
now=$(date +'%Y%m%d_%H%M%S')
command=$1
[[ -z $command ]] && usage && exit 1
shift 1
str="${strorig#+(* )}"
mval="null"

#set -vx
#while getopts :m:tl name ${str}; do
unset OPTIND
while getopts :m:r:tl name; do
	DBG zzy:$name
	case $name in
		  l)  lflag=1
			;;
		  t)  tflag=1
			;;
		  m)  mval=${OPTARG:-null};
			;;
		  r)  rval=${OPTARG:-null};
			;;
		  \?) echo "invalid option $name";
		     	usage
			 exit 0
			;;
	esac
	unset OPTARG
done
DBG "lflag=$lflag;tflag=$tflag;mval=$mval"

if [ ! -z $lflag ] ; then
     DBG "option -l specified"
     DBG  "$aflag"
     DBG  "$OPTIND"
fi

shift $(($OPTIND -1))
DBG " shift $(($OPTIND -1))" 

case ${command} in
("")
	usage
	return 1
	;;
(ps)
	DBG "list all wine process"
	typeset format=$1
	typeset psopt=${PS_OPT_LONG}
	#[[ ${format} == "long" ]] && psopt="${PS_OPT_LONG}"
	typeset pattern
	for p in ${arywineps[*]}; do
		pattern="${pattern:+"${pattern}|"}${p}"
	done
	DBG "pattern=$pattern"
	DBG "format=${format}"
	if [[ ${format} == "long" ]]; then
		ps -e -o "${psopt}" | egrep "($pattern)" | grep -v grep
	else
		#ps -e -o "${psopt}" | egrep "($pattern)" | grep -v grep | awk '{printf("%s %s %s %s %s %s %s\n", $1,$2,$3,$4,$5,$6,$7)}'
		ps -e -o "${psopt}" | egrep "($pattern)" | grep -v grep | sed 's/ \{1,\}/ /g' | cut -d ' ' -f 1-12
	fi
	;;
(kill)
	DBG "kill all wine process"
	typeset psopt=${PS_OPT_LONG}
	typeset pattern
	for p in ${arywineps[*]}; do
		pattern="${pattern:+"${pattern}|"}${p}"
	done
	DBG "pattern=$pattern"
	ps -e -o "${psopt}" | egrep "($pattern)" | grep -v grep | awk '{ print $2}' | xargs -I {} kill -9 {}
	;;
(*)
	showerr "Unknown command: $command "
	usage
	return 1
	;;
esac 


}

###########################################
#g_appname=${0##*/}
#DBG "g_appname=$g_appname"
main ${@:+"$@"}

