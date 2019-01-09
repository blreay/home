#!/bin/bash

typeset lport=10005
typeset rport=139
typeset force=0

function init_adb {
	adb kill-server
	adb start-server
	if [[ $? -ne 0 ]]; then
		 netstat -ano|grep ":5037"|awk '{print $5}'|uniq|xargs -I {} tasklist /fi "pid eq {}" /fo table
		 echo "Do you really want to kill these process which is using port 5037 ???"
		 read a
		 if [[ $a = "y" ]]; then
		 	netstat -ano|grep ":5037"|awk '{print $5}'|uniq|xargs -I {} taskkill /pid {} /F
		 fi
		adb kill-server
		adb start-server
	fi
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

echo "local port=$lport remote port=$rport"
if [[ $force -eq 1 ]]; then
	init_adb
fi

echo "run: adb forward tcp:$lport tcp:$rport"
adb forward tcp:$lport tcp:$rport
echo $?
