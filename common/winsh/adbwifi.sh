#!/bin/bash

#typeset pkgname="com.dzt.downloadimage"
typeset pkgname="com.blreay.wifimng"
typeset actyname=${pkgname}.MainActivity
typeset force=0
typeset execpath=$(cygpath "C:\Program Files (x86)\SFTP Net Drive\SftpNetDrive.exe")
typeset ftpexecpath=$(cygpath "D:\zhangzy\Tools_Sort\NetWork\Download\FlashFXP5_gr\FlashFXP\flashfxp.exe")
typeset ftplocalpath="G:\zhangzy\CoolPad_F1\SD Card"
typeset ftplocalpath="G:\zhangzy\CoolPad_F1"
typeset ftpremotepath="/storage/sdcard1/zzy/pic"
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

function startapp {
	adb shell am start $1
}

function stopapp {
	adb shell am force-stop $1
	adb shell am kill $1
}
function testnet {
	typeset tmpfile=/tmp/ping.tmp00
	typeset retrymax=180
	typeset retry=0
	while [[ $retry -lt $retrymax ]]; do
		(( retry = retry + 1 ))
		## ping output: 3 packets transmitted, 0 received, 100% packet loss, time 2001ms
		adb shell ping -c 3 www.baidu.com |egrep "(unknown|[^0-9]0[^0-9,]*received)" && sleep 1 && echo "retry ($retry/$retrymax)" && continue || echo "WIFI OK" && return 0
	done
	return 1
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

showmsg "start wifi login on phone"
#adb devices
# kill the existing process, so that it can reload sms message 
showmsg "kill $pkgname at first"
stopapp $pkgname
startapp $pkgname/$actyname
testnet
### don't stop it so that it can keep in background
#stopapp $pkgname
##################################

#echo $?
