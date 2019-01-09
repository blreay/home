#!/bin/bash

typeset MYNFS="zhaozhan@bej301713.cn.oracle.com:/nfs/users/zhaozhan/"
typeset tmp_file=/tmp/curl.sendpwd
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


function backup_onefolder {
	fn=$1
	echo "process: $fn"
	mkdir -p "${NFS}/$fn/"
	scp -r "${MYNFS}/$fn/*" "${NFS}/$fn/"
}

###################################################

#################################################
function main {
#strorig=$@
#str="${strorig#+(* )}"

while getopts :d:s: name ; do
	showdbg zzy:$name
	case $name in
		  d)  olddel=$OPTARG
			;;
		  s)  newdel=$OPTARG
			;;
		  \?) echo "invalid option $name";
		     	show_usage
			 exit 0
			;;
	esac
	unset OPTARG
done
showdbg "olddel=$olddel newdel=$newdel"

shift $(($OPTIND -1))
showdbg " shift $(($OPTIND -1))"
str=$1
str="aaa"

case ${str} in
("")
	show_usage
	return 1
	;;
(*)
	showdbg "show $str"
	echo $str|tr "$olddel" "$newdel"
	;;
esac 

[[ -z $NFS ]] && showerror "NFS is not set on local" && exit 1

backup_onefolder "common/sh"
backup_onefolder "test"

}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

