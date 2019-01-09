#!/bin/bash

#set -vx
typeset pid=$1

if [[ -z $USER ]]; then
	USER=$(id|tr '()' '  '|awk  '{print $2}' 2>&1); export USER
fi


if [[ -z "$pid" ]]; then
	case $(uname) in
		(SunOS) [ -f /usr/ucb/ps ] && PSCMD1="/usr/ucb/ps auxwww" || PSCMD1="ps -ef"
		#PSCMD="$PSCMD1 auxwww"
		PSCMD="$PSCMD1"
		;;
		(*)     PSCMD="ps -ef"
		;;
	esac

	if [[ -n $USER ]]; then
		## long user name will be trimed to zhaoyon+
		$PSCMD |egrep  "^[ \t]*${USER:0:7}"
	else
		echo "USER is null"
	fi
else
	ps --pid "$pid" -o pid -o ppid -o ruid -o euid -o suid -o fuid -o fname
fi

