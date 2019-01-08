#!/bin/ksh

function show_usage {
	echo "Usage: ${0##*/} user@hostname"
}

#set -vh
#########################################################################
## Check Paramter ##
while getopts :d:g:m: name; do
	case $name in
	  d)  use_db_direct=1; export g_MaxGen=$OPTARG;;
	  g)  gflag=1; maxgen=$OPTARG;;
	  m)  mflag=1; gennumlist=$OPTARG ;;
	  ?)  show_usage; echo aaa; exit 1 ;;
	esac
done

PID=$1 
[[ -z "$PID" ]] && show_usage && exit 1

cat /proc/$PID/environ | tr '\0' '\n'
