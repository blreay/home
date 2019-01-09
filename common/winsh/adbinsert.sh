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
#############################

function sendmsg {
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	cmd /c msg \* /time:3 $msg
}


#####################################################################
## Main
function main {
	unset OPTIND
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
	shift $((OPTIND-1))
	typeset type=$1
	#############################
	echo "Do all aticion when phone is connected: ${type}"
	#return 0

	if [[ ${type} == "xiaomi" ]]; then
		adbssh.sh -k && adbrunapp.sh -r && { adbwifi.sh& } && adbssh.sh && adbrunapp.sh -k \
			&& { true || adbblink.sh; } && sendmsg
	else 
		adblock.sh && adbclean.sh && adbrunapp.sh -r \
			&& { adbwifi.sh& } && adbssh.sh && adbrunapp.sh -k \
			&& { true || adbblink.sh; } && sendmsg
	fi

	echo $?
}
#########################

#main ${@} | sed '/^WARNING: linker/d'
main ${@}
