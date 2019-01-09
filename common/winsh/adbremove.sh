#!/bin/bash

########################################## 
function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] string"
    showerr "        -d : specify the delimiter" 
    showerr "        -s : specify the new delimiter" 
}

function showdbg {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	echo ${@:+"$@"} >&2
}
function showmsg {
	echo ${@:+"$@"}
}
function ps_kill {
	#echo ${@:+"$@"}
	[[ -n $1 ]] && procps -ef |grep $1| grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {} 
}
#############################


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
echo "Do all aticion when phone is removed"

#ps -ef | grep adbinsert.sh
ps_kill adbssh.sh
ps_kill FlashFXP.exe
#procps -ef |grep adbssh | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {} 
#procps -ef |grep FlashFXP.exe | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {} 
#taskkill /f /im FlashFXP.exe

echo $?
#########################
