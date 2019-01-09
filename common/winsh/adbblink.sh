#!/bin/bash

typeset pkgname="com.dzt.downloadimage"
typeset actyname=${pkgname}.MainActivity
typeset force=0
typeset execpath=$(cygpath "C:\Program Files (x86)\SFTP Net Drive\SftpNetDrive.exe")
typeset ftpexecpath=$(cygpath "D:\zhangzy\Tools_Sort\NetWork\Download\FlashFXP5_gr\FlashFXP\flashfxp.exe")
typeset ftplocalpath="G:\zhangzy\CoolPad_F1\SD Card"
typeset ftplocalpath="G:\zhangzy\CoolPad_F1"
typeset ftpremotepath="/storage/sdcard1/zzy/pic"

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
	adb shell ping -c 3 www.baidu.com
}
function turn_off_screen {
if [ "$(adb shell dumpsys power | grep mScreenOn= | grep -oE '(true|false)')" == false ] ; then
    echo "Screen is already off."
    #adb shell input keyevent 26 # wakeup
	#adb shell input keyevent KEYCODE_POWER
    #adb shell input touchscreen swipe 930 380 1080 380 # unlock
    #echo "OK, screen should be on now."
else 
    echo "Screen is on, turning off"
    adb shell input keyevent 26 # wakeup
    echo "OK, screen should be off now."
    #echo "Turning off."
    #adb shell input keyevent 26 # sleep
fi
}

function turn_on_screen {
	if [ "$(adb shell dumpsys power | grep mScreenOn= | grep -oE '(true|false)')" == false ] ; then
		echo "Screen is off. Turning on."
		#adb shell input keyevent 26 # wakeup
		adb shell input keyevent KEYCODE_POWER
		sleep 1
		#adb shell input touchscreen swipe 930 380 1080 380 # unlock
		echo "OK, screen should be on now."
	else 
		echo "Screen is already on."
		#echo "Turning off."
		#adb shell input keyevent 26 # sleep
	fi 
	echo "Wakeup screen and stay on forever (disabled)"
	#adb shell svc power stayon true
}

function blink_screen {
adb shell >/dev/null <<-EOF
input keyevent KEYCODE_POWER
input keyevent KEYCODE_POWER
input keyevent KEYCODE_POWER
input keyevent KEYCODE_POWER
input keyevent KEYCODE_POWER
exit
EOF
}

#####################################################################
## Main
while getopts :fp:ls name; do
	case $name in
	p) lport=$OPTARG
		echo "aa"
		;;
	f) force=1
		;;
	l) turn_off_screen; echo "Done"; exit 0
		;;
	s) netstat -ano|grep ":5037"
	   netstat -ano|grep ":5038"|awk '{print $5}'|uniq|xargs -I {} tasklist /fi "pid eq {}" /fo table
		exit 0
		;;
	*) echo "wrong parameter: $name"
		exit 1;
		;;
	esac
done

#echo "local port=$lport remote port=$rport"
if [[ $force -eq 1 ]]; then
	init_adb
fi

echo "blink screen"
blink_screen 

