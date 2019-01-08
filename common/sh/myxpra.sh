#!/bin/bash

###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo

typeset g_appname
############################################## 
function DBG {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}" >&2
} 
function LOG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
} 
function ERR {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}" >&2
} 
function MSG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "%s\n" "${arg}"
} 
############################################## 

typeset DPI="--dpi=96"
typeset g_appname
typeset arywineps=(
wineserver
winedevice.exe
winecfg.exe
winedbg
wineboot.exe
winemenubuilder.exe
WeChat.exe
services.exe
plugplay.exe
explorer.exe
QQ.exe
tencentdl.exe
QQSetupEx.exe
QQProtect.exe
)

typeset aryHost=(
"bej301459"
"bej301712"
"bej301738"
)

typeset jsonapp=$(cat - <<\EOF
{
  "app":{
	  "firefox":    {"host":"host1",  "port":"7901",   "msg":""},
	  "firefox2":   {"host":"host2",  "port":"31000",  "msg":""},
	  "gedit":      {"host":"host2",  "port":"31001",  "msg":""},
	  "wechat":     {"host":"host2",  "port":"7908",   "msg":""}
  },
  "host":{
	  "host1":"bej301459.cn.oracle.com",
	  "host2":"bej301712.cn.oracle.com",
	  "host3":"bej301713.cn.oracle.com",
	  "host4":"slc09wou.us.oracle.com"
  }
}
EOF
)

function getappinfo {
	info=$1
	appname=$2
	vname=$3
	[[ -z ${appname} || -z ${vname} ]] && ERR "" && return 1
	result=$(echo "${jsonapp}" | jq -r '.app.'"${appname}"'.'"${info}"'')
	eval ${vname}="\${result}"
}
function gethostinfo {
	hostname=$1
	vname=$2
	[[ -z ${appname} || -z ${vname} ]] && ERR "" && return 1
	result=$(echo "${jsonapp}" | jq -r '.host.'"${hostname}"'')
	eval ${vname}="\${result}"
}

function set_proxy {
	[[ "no" == "$1" ]] && unset http_proxy HTTP_PROXY https_proxy ftp_proxy && echo "proxy has been disabled $(env|grep -i proxy)" && return
	export HTTP_PROXY=http://cn-proxy.jp.oracle.com:80
	[[ "us" == "$1" ]] && export HTTP_PROXY=http://www-proxy.us.oracle.com:80
	export http_proxy=$HTTP_PROXY
	export https_proxy=$HTTP_PROXY
	export ftp_proxy=$HTTP_PROXY
	env|grep -i proxy
}

function gen_wechat_shell {
typeset vn=$1 
typeset fn=/tmp/_axwc
cat <<\EOF > ${fn}
#!/bin/bash

export HTTP_PROXY=http://cn-proxy.jp.oracle.com:80
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTP_PROXY
export ftp_proxy=$HTTP_PROXY

#exe="/nfs/users/zhaozhan/share/Tools/Wechat/electronic-wechat-linux-x64/electronic-wechat"
exe="/nfs/users/zhaozhan/share/Tools/chrome/chrome"
#CMD="xpra start ${DPI} --start-child=\"export http_proxy=$HTTP_PROXY; ${exe}\" --bind-tcp=0.0.0.0:31007 --input-method=fcitx --start=\"fcitx -r\""
${exe}

EOF

chmod +x ${fn}
eval ${vn}="${fn}"
}

function show_usage {
	MSG "Usage: ${g_appname##*/} command [-l] [-t] [-m msg]"
    MSG "   command : kill "
    MSG "        -l : show result in one line" 
    MSG "        -t : just list the target files without real action"
    MSG "           : rm/commit will read file list from stdin"
}

function cvs_add_one_folder {
	typeset dirname="$1"
}

############################################################
function main { 
	############################################
	export g_apppath=${0}
	export g_appname=${0##*/}
	[[ ${g_appname} == "bash" ]] && export g_apppath=`pwd`/
	# set debug
	unset OPTIND
	while getopts :s:p:dh ch; do
		DBG "ch=$ch"
		case $ch in
		"d") export MYDBG=DEBUG;;
		"h") usage; return 0;;
		*) echo "wrong parameter $ch"; return 1;;
		esac
	done
	shift $((OPTIND-1))
	DBG "g_appname=$g_appname"
	DBG "g_apppath=$g_apppath"
	DBG "\$@=$@"
	############################################

strorig="${@}"
now=$(date +'%Y%m%d_%H%M%S')
app=$1
command=${2:-attach}
[[ -z $command ]] && show_usage && exit 1
shift 1
str="${strorig#+(* )}"
mval="null"
typeset appport=""
typeset apphost=""
getappinfo port "${app}" appport
getappinfo host "${app}" apphost
gethostinfo "${apphost}" apphost
MSG "URL: ${apphost}:${appport}"

#set -vx
#while getopts :m:tl name ${str}; do
unset OPTIND
while getopts :m:r:tl name; do
	DBG zzy:$name
	case $name in
		  l)  lflag=1
			;;
		  t)  tflag=1
			;;
		  m)  mval=${OPTARG:-null};
			;;
		  r)  rval=${OPTARG:-null};
			;;
		  \?) echo "invalid option $name";
		     	show_usage
			 exit 0
			;;
	esac
	unset OPTARG
done
DBG "lflag=$lflag;tflag=$tflag;mval=$mval"

if [ ! -z $lflag ] ; then
     DBG "option -l specified"
     DBG  "$aflag"
     DBG  "$OPTIND"
fi

shift $(($OPTIND -1))
DBG " shift $(($OPTIND -1))" 
DBG "commnd:${command}"
#set -vx

[[ $(uname) =~ CYGWIN ]] && export XPRACMD="xpra_cmd.exe" || export XPRACMD="xpra"

case "${command}" in
###########################################################################################################
("attach")
	CMD="${XPRACMD} attach  --bell=no --speaker=off -d notify,dbus tcp/zz:love521@${apphost}:${appport}/ &"
	LOG "${CMD}"
	eval "${CMD}"
	;;
###########################################################################################################
("info")
	CMD="lsof -i:${appport}"
	LOG "${CMD}"
	eval "${CMD}"
	mainpid=$(lsof -i:${appport}|grep LISTEN|awk '{print $2}')
	LOG "mainpid: ${mainpid}"
	LOG "##################################"
	[[ -n "${mainpid}" ]] && mykilltree.sh ${mainpid} list
	case ${app} in
	("wechat")
		mywine.sh ps
		;;
	esac
	LOG "##################################"
	;;
###########################################################################################################
("kill")
	mainpid=$(lsof -i:${appport}|grep LISTEN|awk '{print $2}')
	LOG "mainpid: ${mainpid}"
	LOG "##################################"
	[[ -n "${mainpid}" ]] && mykilltree.sh ${mainpid} all
	case ${app} in
	("wechat")
		mywine.sh kill
		;;
	esac
	LOG "##################################"
	;;
########################################################################################################### 
("start")
	case ${app} in
	(firefox*)
		#slack --proxy-server=www-proxy.us.oracle.com:80
		#CMD="${XPRACMD} start ${DPI} --start-child=firefox --bind-tcp=0.0.0.0:${appport}"
		CMD="${XPRACMD} start ${DPI} --start-child=firefox --bind-tcp=0.0.0.0:${appport} --input-method=fcitx --start=\"fcitx -r\""
		;;
	("gedit")
		#slack --proxy-server=www-proxy.us.oracle.com:80
		CMD="${XPRACMD} start ${DPI} --start-child=gedit --bind-tcp=0.0.0.0:${appport} --input-method=IBus"
		CMD="${XPRACMD} start ${DPI} --start-child=gedit --bind-tcp=0.0.0.0:${appport} --input-method=fcitx"
		CMD="${XPRACMD} start ${DPI} --start-child=gedit --bind-tcp=0.0.0.0:${appport} --input-method=fcitx --start=\"fcitx -r\""
		;;
	("gedit2")
		#slack --proxy-server=www-proxy.us.oracle.com:80
		CMD="${XPRACMD} start ${DPI} --start-child=gedit --bind-tcp=0.0.0.0:${appport} --html=on --input-method=fcitx --start=\"fcitx -r\""
		;;
	("qq")
		#slack --proxy-server=www-proxy.us.oracle.com:80
		CMD="${XPRACMD} start ${DPI} --start-child=/home/zhaozhan/download --bind-tcp=0.0.0.0:${appport} --html=on --input-method=fcitx --start=\"fcitx -r\""
		;;
	("slack")
		#slack --proxy-server=www-proxy.us.oracle.com:80
		#CMD="${XPRACMD} start ${DPI} --start-child=\"slack --proxy-server=www-proxy.us.oracle.com:80\" --bind-tcp=0.0.0.0:${appport}"
		CMD="${XPRACMD} start ${DPI} --start-child=\"slack --proxy-server=www-proxy.us.oracle.com:80\" --bind-tcp=0.0.0.0:${appport} --input-method=fcitx --start=\"fcitx -r\""
		;;
	("gnome")
		#CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1024x768\" --start=gnome-terminal --bind-tcp=0.0.0.0:${appport}"
		#CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1024x768\" --start=/etc/X11/xinit/xinitrc --bind-tcp=0.0.0.0:${appport} --html=on"
		#CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1216x896\" --start=/etc/X11/xinit/xinitrc --bind-tcp=0.0.0.0:${appport} --html=on −−notifications=yes −−dbus−control=yes"
		CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1216x896\" --start=/etc/X11/xinit/xinitrc --bind-tcp=0.0.0.0:${appport}  --start=\"xrandr -s 1216x896\" --no-printing --no-speaker --html=on"
		;;
	("wechat")
		outfile=/home/zhaozhan/wx/vm/wx.sh
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} --html=on"
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport}"
		#CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1024x768\" --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport}"
		#CMD="${XPRACMD} start-desktop ${DPI} --start=\"xrandr -s 1216x896\" --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport}  --start=\"xrandr -s 1216x896\" --no-printing --no-speaker --html=on"

		## following can work, X server running in remote Linux, "DISPLAY=:27 gedit&" can verify it. close xpra window will not cause wine exit, clipboard work, good
		CMD="${XPRACMD} start-desktop ${DPI} --start-child=\"${outfile}\" --start=\"xrandr -s 1024x768\" --tcp-auth=password:value=love521 --bind-tcp=0.0.0.0:${appport} --bell=no --no-printing --printing=no --speaker=off  --no-speaker --html=on" 
		## following can work, but the X server is running in my win10 in fact, and if close the attached xpra window, wine will exit also
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport}  --no-printing --no-speaker --html=on" 
		;;
	("wechatweb")
		#slack --proxy-server=www-proxy.us.oracle.com:80
		#CMD="${XPRACMD} start ${DPI} --start-child=\"slack --proxy-server=www-proxy.us.oracle.com:80\" --bind-tcp=0.0.0.0:${appport}"
		#set_proxy
		#exe="$NFS/share/Tools/Wechat/electronic-wechat-linux-x64/electronic-wechat"
		gen_wechat_shell outfile
		cat ${outfile}
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} −−notifications=yes --input-method=fcitx --start=\"fcitx -r\""
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} --input-method=fcitx --start=\"fcitx -r\""
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} --html=on −−notifications=yes −−dbus−control=yes"
		CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} --html=on"
		#CMD="${XPRACMD} start ${DPI} --start-child=\"${outfile}\" --bind-tcp=0.0.0.0:${appport} −−notifications=yes --input-method=fcitx --start=\"fcitx -r\""
		;;
	(*)
		ERR "Unknown app: ${app}"
		show_usage
		return 1
		;;
	esac 
	MSG "${CMD}"
	eval ${CMD}
	return 0
	;;
(*)
	ERR "Unknown command: ${command}"
	show_usage
	return 1
	;;
esac 
}

###########################################
main ${@:+"$@"}

