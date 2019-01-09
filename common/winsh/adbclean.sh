#!/bin/bash

typeset -a ary_folder=(
/data/media/0/kugou/down_c/default
/data/media/0/tencent/MicroMsg/crash
/data/media/0/tencent/MicroMsg/xlog
/data/media/0/com.excelliance.dualaid/0/tencent/MicroMsg/be8faf12605c6f0a374c5246ed1d0947/video
/data/media/0/com.excelliance.dualaid/0/tencent/MicroMsg/xlog
#/data/media/0/com.excelliance.dualaid/0
/data/data/com.tencent.news/app_hotpatch
/data/data/com.taobao.taobao/files
/data/data/com.tencent.android.qqdownloader/files
/data/media/0/kugou/.fssingerres
/data/media/0/minius/cloakShop
/data/media/0/Android/data/com.kugou.android
/data/media/0/Android/data/com.tencent.mobileqq
/data/media/0/qqmusic
/data/media/0/gifshow
/data/media/0/immomo
#/data/media/0/Tencent
#/data/media/0/tencent
)

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

function sendmsg {
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	cmd /c msg \* /time:3 $msg
}

function clean_folder {
for folder in ${ary_folder[*]}; do
	showmsg "clean $folder"
	#adb shell su -c "ls $folder"
	adb shell su -c "rm $folder/\*"
done
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
	*) echo "wrong parameter: $name"
		exit 1;
		;;
	esac
done 
#############################
showmsg "Clean files and folders"
clean_folder 

echo $?
#########################
