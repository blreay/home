#!/bin/bash

#for ssh
typeset lport=10010
typeset rport=10010
#for FTP
typeset lport_ftp=10050
typeset rport_ftp=10050
typeset passive_port1_ftp=10051
typeset passive_port2_ftp=10052

typeset ftp_activity="berserker.android.apps.ftpdroid/berserker.android.apps.ftpdroid.MainActivity"
typeset ftp_activity2="com.sqzsoft.freeftpserver/com.sqzsoft.freeftpserver.ActivityMain"
#typeset ftp_activity="com.sqzsoft.freeftpserver/com.sqzsoft.freeftpserver.ActivityMain"

typeset force=0
typeset execpath=$(cygpath "C:\Program Files (x86)\SFTP Net Drive\SftpNetDrive.exe")
typeset ftpexecpath=$(cygpath   "D:\mydisk\tools\network\download\FlashFXP\FlashFXP.exe")
typeset ftplocalpath="D:\zzy\myphone"
typeset ftpremotepath="/storage/sdcard1/zzy/pic"
#typeset ftp_url="ftp://root:admin@localhost:$lport_ftp"
typeset ftp_url="zzy\phone"
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

function startssh {
	adb shell am start com.icecoldapps.sshserver/com.icecoldapps.sshserver.viewStart
}

function stopssh {
	adb shell am force-stop com.icecoldapps.sshserver
	adb shell am kill com.icecoldapps.sshserver
}
function startftp {
	#adb shell pm list packages |grep ftp
	#adb shell dumpsys window w |grep name= 
	#adb shell am start berserker.android.apps.ftpdroid/berserker.android.apps.ftpdroid.MainActivity
	adb shell am start ${ftp_activity} 2>&1 | grep Error
	## the first ftp server only work in the init space,
	[[ $? -eq  0 ]] && adb shell am start ${ftp_activity2} 
}
function stopftp {
	#adb shell am force-stop berserker.android.apps.ftpdroid
	#adb shell am kill berserker.android.apps.ftpdroid
	#appname=${ftp_activity%%/*}
	for appname in ${ftp_activity%%/*} ${ftp_activity2%%/*}; do
		adb shell am force-stop $appname
		adb shell am kill $appname
	done
}
function port_forward_ftp {
	for i in $lport_ftp $passive_port1_ftp $passive_port2_ftp; do
		typeset lport=$i
		typeset rport=$i
		echo "run: adb forward tcp:$lport tcp:$rport"
		adb forward tcp:$lport tcp:$rport
	done
}

#####################################################################
## Main
function main {
	while getopts :fp:sk name; do
		case $name in
		p) lport=$OPTARG
			showmsg "aa"
			;;
		k)  showmsg "stop ftp server"
			stopftp
			return 0
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

	#echo "local port=$lport remote port=$rport"
	[[ $force -eq 1 ]] && adb devices && init_adb 

	#############################
	echo "Wakeup screen and stay on forever (disabled)"
	#adb shell svc power stayon true

	#############################
	echo "start FTP server on the phone"
	#startssh
	startftp
	lport=$lport_ftp

	#############################
	#echo "run: adb forward tcp:$lport tcp:$rport"
	#adb forward tcp:$lport tcp:$rport
	port_forward_ftp

	#"$execpath" &
	#set -vx
	#sleep 1
	#echo "press any key to stop SSH server on the phose after close - $ftpexecpath"
	echo "Waitting Process - $ftpexecpath"
	#"${ftpexecpath}"  -localpath="${ftplocalpath}" -remotepath="$ftpremotepath" sftp://root:admin@localhost:$lport
	"${ftpexecpath}" -localpath="${ftplocalpath}" -remotepath="$ftpremotepath" $ftp_url

	#################################
	#tasklist|grep SftpNetDrive|awk '{print $2}' | xargs -I {} taskkill /F /PID {}
	#stopssh
	stopftp

	echo $?
	#########################
}

main $@
