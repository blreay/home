#!/bin/bash

typeset g_appname
typeset olddel=":"
typeset newdel="\n"

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
#set -vx

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


}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

