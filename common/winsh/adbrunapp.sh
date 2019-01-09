#!/bin/bash

#typeset -a applist_run=("com.fsck.k9" "cn.wiz.note/cn.wiz.note.MainActivity" "com.baidu.BaiduMap/com.baidu.baidumaps.MapsActivity")
#typeset -a applist_run=("com.fsck.k9" "cn.wiz.note/cn.wiz.note.MainActivity" "com.baidu.BaiduMap")
### if kill baidu_map, then GPS can NOT be turn off unless reboot phone.
typeset -a applist_run=(
"nokill:com.fooview.android.fooview/.MainActivity"
"com.fsck.k9" 
"cn.wiz.note/cn.wiz.note.MainActivity"
"com.tencent.android.qqdownloader/com.tencent.assistantv2.activity.MainActivity"
"com.baidu.BaiduMap"
)
typeset pkgname="com.dzt.downloadimage"
typeset actyname=${pkgname}.MainActivity
typeset execpath=$(cygpath "C:\Program Files (x86)\SFTP Net Drive\SftpNetDrive.exe")
typeset ftpexecpath=$(cygpath "D:\zhangzy\Tools_Sort\NetWork\Download\FlashFXP5_gr\FlashFXP\flashfxp.exe")
typeset ftplocalpath="G:\zhangzy\CoolPad_F1\SD Card"
typeset ftplocalpath="G:\zhangzy\CoolPad_F1"
typeset ftpremotepath="/storage/sdcard1/zzy/pic"
typeset force=0
typeset killapp=0
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
	CMD="adb shell am start $1"
	echo "${CMD}"
	eval ${CMD}
} 
function stopapp {
	pkgname=${1%/*}
	adb shell am force-stop $pkgname
	adb shell am kill $pkgname
}
function testnet {
	adb shell ping -c 3 www.baidu.com
}
function startall {
	for i in ${applist_run[*]}; do
		startapp ${i/nokill:/} 2>/dev/null
	done
	## make fooview disappear, i have no other way to do this
	adb shell input keyevent KEYCODE_BACK
	adb shell input keyevent KEYCODE_BACK
	return 0
}
function stopall {
	for i in ${applist_run[*]}; do
		[[ $i =~ ^nokill: ]] && showmsg "Do not kill app: $i" && continue
		showmsg "kill app: $i"
		stopapp $i
	done
	return 0
} 
#####################################################################
## Main
function main {
while getopts :fp:s:kr name; do
	case $name in
	p) lport=$OPTARG
		echo "aa"
		;;
	f) force=1
		;;
	k) killapp=1
		;;
	r) runapp=1
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

#echo "local port=$lport remote port=$rport"
if [[ $force -eq 1 ]]; then
	init_adb
fi

[[ $force -eq 1 ]] && adb devices

## kill all app
[[ $killapp -eq 1 ]] && { stopall && exit 0 || exit 1;  }

## run all app
[[ $runapp -eq 1 ]] && { startall && exit 0 || exit 1; }

############################################
# No option is specified
############################################
startall
echo -e "**************************************"
echo -e "Current Active app: \n$( echo ${applist_run[*]} | tr ' ' '\n')"
echo -e "**************************************"
echo -e "Press any key to stop above active app"
read DD
echo "Begin to kill app"
stopall
echo $?
}

#main ${@} | sed '/WARNING: linker/d'
main ${@}
