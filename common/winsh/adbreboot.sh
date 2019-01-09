#!/bin/bash

#typeset -a applist_run=("com.fsck.k9" "cn.wiz.note/cn.wiz.note.MainActivity" "com.baidu.BaiduMap/com.baidu.baidumaps.MapsActivity")
#typeset -a applist_run=("com.fsck.k9" "cn.wiz.note/cn.wiz.note.MainActivity" "com.baidu.BaiduMap")
### if kill baidu_map, then GPS can NOT be turn off unless reboot phone.
typeset -a applist_run=("com.fsck.k9" "cn.wiz.note/cn.wiz.note.MainActivity" "com.tencent.android.qqdownloader/com.tencent.assistantv2.activity.MainActivity")
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
## Main
function main {
	adb shell su root reboot
	echo $?
}

#main ${@} | sed '/WARNING: linker/d'
main ${@}
