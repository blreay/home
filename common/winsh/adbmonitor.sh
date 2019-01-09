#!/bin/bash

##how to get activity name and package name
##adb logcat -c
##adb logcat ActivityManager:I *:s

typeset g_xiaomi_dev_id="88e8b4cf"  ##get from "adb devices"
typeset applock="/tmp/adbmonitor.sh.lock"
trap "printf 'trap signal: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 1; }" EXIT

########################################## 
function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] string"
    showerr "        -d : specify the delimiter" 
    showerr "        -s : specify the new delimiter" 
}

function showdbg {
	if [[ ${MYDBG^^} =~ YES|DEBUG ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	#echo ${@:+"$@"} >&2
	echo -e "[$(date +'%Y%m%d %H:%M:%S')] ${@:+"$@"}" >&2
}
function showmsg {
	#echo ${@:+"$@"}
	echo -e "[$(date +'%Y%m%d %H:%M:%S')] ${@:+"$@"}" 
}
function mylockfile {
	typeset ch=
	typeset act="lock"
	typeset lock=
	unset OPTIND
	while getopts :ul ch; do
		showdbg "ch=$ch"
		case $ch in
		l) act=lock;;
		u) act=unlock;;
		esac
	done
	shift $(($OPTIND - 1))
	lock=$1
	showdbg "act=$act  lock=$lock"
	[[ -z "$lock" ]] && showerr "internal error, need to specify lock file" && return 1
	[[ "$act" == "lock" ]] && { lockfile -1 -r 0 "$lock"; return $?; }
	[[ "$act" == "unlock" ]] && { rm -f "$lock"; return $?; }
}
#############################
function waitpid {
	typeset pid=$1
	while true; do
		kill -0 $pid && sleep 1 && continue
		break
	done
}
function kill_previous_ftp {
	typeset insertps=$(procps -ef | egrep "adbinsert.sh" | egrep -v "(vim|egrep)"|awk '{print $2}')
	showdbg "insertps=$insertps"
	for insertpid in $insertps; do
		ftppid=$(killpstree.sh ${insertpid} test | grep FlashFXP.exe | awk '{print $2}')
		[[ -n "${ftppid}" ]] && { kill -9 ${ftppid}; waitpid ${insertpid}; }
	done
}

function usb_changed {
	typeset retry=1
	typeset retry_max=3
	while [[ ${retry} -le ${retry_max} ]]; do
		typeset devid=$(adb devices |grep -v "List of" | grep "${g_xiaomi_dev_id}" | tr -d '\r\n\r\n' | awk '{print $1}')	
		showdbg "devid=${devid}"
		case "${devid}" in
			("${g_xiaomi_dev_id}")  showmsg "xiaomi device is connected"; export ANDROID_SERIAL="${devid}"; kill_previous_ftp; adbinsert.sh "xiaomi"; return 0;;
			("")  showmsg "OMG: no android devices is found(${retry}/${retry_max})";;
		esac
		((retry++))
		#sleep 1
	done
}

#####################################################################
## Main
while getopts :fp:s name; do
	case $name in
	p) lport=$OPTARG
		echo "aa"
		;;
	f) force=1
		;;
	s) netstat -ano|grep ":5037"
	   netstat -ano|grep ":5037"|awk '{print $5}'|uniq|xargs -I {} tasklist /fi "pid eq {}" /fo table
		exit 0
		;;
	*) echo "wrong parameter: $name"
		exit 1;
		;;
	esac
done 
#############################

mylockfile -l "$applock"
[[ $? -ne 0 ]] && echo "another instance is running" && { 
	typeset runningproc=$(procps -ef | egrep "${0#./}$" | egrep -v "(vim|egrep| $$ )")
	[[ -n "$runningproc" ]] && echo $runningproc && trap '' EXIT && exit 1
	[[ -z "$runningproc" ]] && echo "in fact no instance is running, maybe the previous instance crashed"
}


#CMD_WAIT_ADB="$(cygpath "C:\Users\zhaozhan\Documents\Visual Studio 2015\Projects\Win32Project2\Debug\Win32Project2.exe")"
#CMD_WAIT_ADB="adbdetect.exe"
CMD_WAIT_ADB="usbmonitor.exe"

showmsg CMD=$CMD_WAIT_ADB
while true; do
	showmsg "==== Waitting adb device insert/remove ===="
	#######################################
	# drive letter is the CDROM drive with created by android phone driver ###
	# if it's not created, should remove this argument so that all usb device will be monitored
	#"$CMD_WAIT_ADB" hide drive=f
	#event_interval is used to control the 2 DBT_DEVNODES_CHANGED event interval (ms)
	"$CMD_WAIT_ADB" hide drive=f event_interval=4000
	#######################################
	case $? in
	0) showmsg "receive exit command"; exit 0;;
	1) showmsg "USB inserted" && unset ANDROID_SERIAL && adbinsert.sh  | sed '/^WARNING: linker/d' & sleep 3 ;;
	2) showmsg "USB removed" && adbremove.sh | sed '/^WARNING: linker/d' & sleep 3;;
	3) showmsg "USB changed" && usb_changed & sleep 30;; ##sleep 3 second to avoid multiple USB event is received
	?) showmsg "Unknown exit code, retry";;
	esac 
done
echo $?
#########################
