#!/bin/bash

typeset pkgname="com.dzt.downloadimage"
typeset actyname=${pkgname}.MainActivity
typeset force=0
typeset execpath=$(cygpath "C:\Program Files (x86)\SFTP Net Drive\SftpNetDrive.exe")
typeset ftpexecpath=$(cygpath "D:\zhangzy\Tools_Sort\NetWork\Download\FlashFXP5_gr\FlashFXP\flashfxp.exe")
typeset ftplocalpath="G:\zhangzy\CoolPad_F1\SD Card"
typeset ftplocalpath="G:\zhangzy\CoolPad_F1"
typeset ftpremotepath="/storage/sdcard1/zzy/pic"

## only xiaomi device has this feature
export ANDROID_SERIAL=88e8b4cf 

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
#if [ "$(adb shell dumpsys power | grep mScreenOn= | grep -oE '(true|false)')" == false ] ; then
#if adb shell dumpsys power | grep "Display Power: state=OFF" && echo "alreay unlocked"; then
	if ! is_screen_on; then
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

function is_screen_on {
    if adb shell dumpsys power | grep "Display Power: state=OFF"; then
		echo "return 1: OFF"
		return 1
	else
		echo "return 0: ON"
		return 0
	fi
}

function turn_on_screen {
	#if [ "$(adb shell dumpsys power | grep mScreenOn= | grep -oE '(true|false)')" == false ] ; then
    #if adb shell dumpsys power | grep "Display Power: state=OFF" && echo "alreay unlocked"; then
	if ! is_screen_on; then
		echo "Screen is off. Turning on."
		#adb shell input keyevent 26 # wakeup
		adb shell input keyevent KEYCODE_POWER
		sleep 1
		#adb shell input touchscreen swipe 930 380 1080 380 # unlock
		echo "OK, screen should be on now."
	else 
		echo "Screen is already on."
		#adb shell input keyevent KEYCODE_POWER
		#sleep 1
		#adb shell input keyevent KEYCODE_POWER
		#echo "Turning off."
		#adb shell input keyevent 26 # sleep
	fi 
	echo "Wakeup screen and stay on forever (disabled)"
	#adb shell svc power stayon true
	 sleep 1
}

function unlock_gesture_space {
	echo "begin to input gesture0"
	adb shell <<-EOF
	`cat evt.in.10.$1 | sed 's#^#sendevent /dev/input/event2 #g'` 
EOF
	#adb shell input tap 250 250
	#adb shell input tap 800 600
	#adb shell input tap 600 800
}
function unlock_gesture_space_1 {
	echo "begin to input gesture1"
}
function unlock_gesture {
#adb shell >/dev/null <<-EOF
############################
#need to know the key postion of gesture
############################
echo "begin to unlock"
typeset idev="/dev/input/event2"
#adb shell >/dev/null <<-EOF
adb shell <<-EOF
sendevent $idev 0001 330 1
sendevent $idev 0003 48 20
sendevent $idev 0003 53 360
sendevent $idev 0003 54 650
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 600
sendevent $idev 0003 54 650
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 600 
sendevent $idev 0003 54 810
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 360
sendevent $idev 0003 54 810
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0001 330 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
exit
EOF
}
function unlock_gesture_f1 {
#adb shell >/dev/null <<-EOF
############################
#need to know the key postion of gesture
############################
typeset idev="/dev/input/event2"
adb shell >/dev/null <<-EOF
sendevent $idev 0001 330 1
sendevent $idev 0003 48 20
sendevent $idev 0003 53 346
sendevent $idev 0003 54 694
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 571
sendevent $idev 0003 54 717
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 506
sendevent $idev 0003 54 828
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0003 48 20
sendevent $idev 0003 53 349
sendevent $idev 0003 54 872
sendevent $idev 0003 57 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
sendevent $idev 0001 330 0
sendevent $idev 0000 2 0
sendevent $idev 0000 0 0
exit
EOF
}

function shiftUSB {
	echo "swith USB mode"
	adb shell svc usb getFunctions
	[[ "$(adb shell svc usb getFunctions 2>&1)" =~ mtp ]] && adb shell svc usb setFunctions ptp || adb shell svc usb setFunctions mtp
	echo "after swith "
	sleep 2
	adb shell svc usb getFunctions
}
#####################################################################
## Main
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
script_name=$(basename ${0})
echo "DIR=$DIR"
echo "script_name=${script_name}"
cd "${DIR}"

unset OPTIND
while getopts :fp:ls name; do
	case $name in
	p) lport=$OPTARG ;;
	f) force=1 ;;
	l) turn_off_screen; echo "Done"; exit 0 ;;
	s) netstat -ano|grep ":5037"
	   netstat -ano|grep ":5037"|awk '{print $5}'|uniq|xargs -I {} tasklist /fi "pid eq {}" /fo table
		exit 0 ;;
	*) echo "wrong parameter: $name"
		exit 1 ;;
	esac
done
shift $((OPTIND-1))

target=${1:-0}

#echo "local port=$lport remote port=$rport"
if [[ $force -eq 1 ]]; then
	init_adb
fi

echo "turn on/off and unlock the screen"
turn_off_screen
sleep 1
turn_on_screen
adb shell input swipe 300 900 300 100

echo "Begin to unlock gesture"
#adb shell dumpsys window windows | egrep "Surface\(name\=Keyguard" && \
#adb shell dumpsys window Keyguard | egrep "Surface\(name\=Keyguard" && \
#unlock_gesture \
#|| echo "already unlocked"
adb shell dumpsys power | grep "Display Power: state=OFF" && echo "alreay unlocked"

unlock_gesture_space ${target}

shiftUSB

echo "Done"
