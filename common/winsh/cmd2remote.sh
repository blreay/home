#!/bin/bash


## This script used to run one local command line and redirect the result to remote machine

typeset reporthost="bej301738.cn.oracle.com"
typeset reportfile="/nfs/users/zhaozhan/mypc.txt"
typeset cmd="ipconfig"

########################################## 
function show_usage {
	showerr "Usage: ${g_appname##*/} [-h host] [-f filename] cmd"
    showerr "        -h : host" 
    showerr "        -f : filename" 
}

function showdbg {
	if [[ $MYDBG = "DEBUG" ]]; then
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


function main {
	while getopts :f:h:c: name; do
		case $name in
		h) reporthost=$OPTARG
			showdbg "report to: $reporthost"
			;;
		f) reportfile=$OPTARG
			showdbg "report file: $reportfile"
			;;
		c) cmd="$OPTARG"
			showdbg "cmd: $cmd"
			;;
		*) echo "wrong parameter: $name"
			exit 1;
			;;
		esac
	done 
	shift $(($OPTIND-1)) 

	{ 
		echo "=================="
		date +'%Y%m%d_%H%M%S'
		echo "cmd: $cmd"
		{ eval "${cmd}"; }; 
	} | ssh ${reporthost} "dos2unix >> ${reportfile}"

}

#####################################################################
## Main
main "${@}"
############################# 
