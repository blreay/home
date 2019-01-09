#!/bin/bash

## must set LC_ALL=c or LC_ALL=zh_CN.gbk, because all windows command output GBK charset, 
## grep may get "binary data match" result
export LC_ALL=C

typeset muttrc=/tmp/muttrc
typeset mail_to=${MYMAILADDR}
typeset mail_title="test"
typeset MYWIFIFILE=${MYWIFIFILE:-$HOME/wifiinfo.txt} 
typeset tmp_curl=$HOME/curl.login
##########################################

function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] acting"
    showerr "        -d : specify the delimiter" 
    showerr "        -s : specify the new delimiter" 
}
function showdbg_old {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showdbg {
	if [[ $MYDBG = "yes" ]]; then
		typeset msg="${@}"
		typeset funcname=${FUNCNAME[1]}
		typeset file="${BASH_SOURCE[1]:-$0}"
		printf -v msg "$(date +'%Y%m%d %H:%M:%S') %08d [DBG] [${file##*/}][${funcname}] %s\n" "$$" "${msg}"
		printf "%s" "$msg" >&2
		#showerr ${@:+"$@"}
	fi
}
function showerr {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}" >&2
}
function showmsg {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}"
}

function readpwd {
	[[ -z "$1" ]] && showerror "internal error, please specify file"
	cat $1 | awk '/Password:/{print $2}'
}

#################################################
function main {
#actorig=$@
#act="${actorig#+(* )}S"
act=""
unset OPTIND 
while getopts :d:s:io name ; do
	showdbg getopts:$name

	case $name in
		  d)  olddel=$OPTARG;;
		  s)  newdel=$OPTARG;;
		  i)  act=login ;;
		  o)  act=logout ;;
		  \?) echo "invalid option $name";
		     	show_usage
			 exit 0
			;;
	esac
	unset OPTARG
done
showdbg "olddel=$olddel newdel=$newdel"

shift $(($OPTIND -1))
showdbg " shift $(($OPTIND -1))"
#act=$1
#set -vx

[[ -z $act ]] && act="login"

case ${act} in
("")
	show_usage
	return 1
	;;
##########################################################
("logout")
showdbg "show $act"
curl --ciphers AES256-SHA 'http://webauth-redirect.oracle.com/logout.html' -H 'Cookie: s_nr=1454581792067; ORASSO_AUTH_HINT=v1.0~20160205092735; ORA_UCM_INFO=3~B10F1856A28EB24AE040548C2D7068AF~Zhaoyong~Zhang~zhaoyong.zhang@oracle.com; s_cc=true; gpw_e24=no%20value; s_sq=oracledocs%3D%2526pid%253Ddocs%25253Aen-us%25253A%25252Fcd%25252Fe37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%2526pidt%253D1%2526oid%253Dhttp%25253A%25252F%25252Fdocs.oracle.com%25252Fcd%25252FE37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%252523BABEJCBF%2526ot%253DA' -H 'Origin: http://webauth-redirect.oracle.com' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://webauth-redirect.oracle.com/logout.html' -H 'Connection: keep-alive' --data 'userStatus=1&err_flag=0&err_msg=' --compressed -v
;;
##########################################################
("login")
showdbg "show $act"
pwd=$(readpwd $MYWIFIFILE)
if [[ -z "$pwd" ]]; then 
	## password is empty, fetch it 
	showmsg "password is empty, fetch it from server"
	getwifipwd.sh 2>&1 | tee $MYWIFIFILE
	pwd=$(readpwd $MYWIFIFILE)
else
	showmsg "read password($pwd) from file: $MYWIFIFILE"
fi
showmsg "password=$pwd" 

typeset -i tried=0
while true; do
	curl --retry 3 --retry-delay 1 --retry-max-time 20 --max-time 60 --ciphers AES256-SHA 'http://webauth-redirect.oracle.com/login.html' --data "buttonClicked=4&redirect_url=www.baidu.com%2F&err_flag=0&username=guest&password=$pwd" --compressed --insecure -v 2>&1 | tee $tmp_curl 
	## maybe need to grep "Web Authentication Failure"
	if egrep "statusCode=(3|5)" $tmp_curl >/dev/null 2>&1; then
		## password is invalid, fetch it again
		showmsg "pwd=$pwd, is wrong, need to refetch again"
		getwifipwd.sh 2>&1 | tee $MYWIFIFILE
		pwd=$(readpwd $MYWIFIFILE)
		showmsg "newpwd=$pwd"
	else if  egrep "statusCode=1" $tmp_curl >/dev/null 2>&1; then
		showmsg "Already login"
		break
	else if  egrep "statusCode=0" $tmp_curl >/dev/null 2>&1; then
		showmsg "login successfully"
		break
	else if  egrep "login_success.html" $tmp_curl >/dev/null 2>&1; then
		showmsg "login successfully"
		break
	else
		showmsg "unknown login result"
		break;
	fi fi fi fi
	## retry one time
	[[ $tried -eq 0 ]] && tried=1 || break;
done
;;
esac 
}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

