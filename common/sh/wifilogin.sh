#!/bin/bash

typeset muttrc=/tmp/muttrc
typeset mail_to=${MYMAILADDR}
typeset mail_title="test"
typeset tmp_pwd=/tmp/curl.pwd
##########################################

function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] acting"
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

###################################################
function gen_mutt_rc {

[[ -z $1 ]] && showerr "no filename for muttrc" && return 1

typeset fn=$1
cat - > $fn <<-EOF
set from = "$SSO_MAIL_ADDR"
set realname = "$SSO_MAIL_NAME"
set imap_user = "$SSO_NAME"
set imap_pass = "$SSO_PWD"
set use_from = yes

#set mbox = +Inbox
#set folder = "imaps://\$imap_user@$SSO_SMTP_ADDR:993"

set smtp_url = "smtps://\$imap_user@$SSO_SMTP_ADDR:$SSO_SMTP_PORT"
set smtp_pass = "\$imap_pass"
set ssl_starttls = yes
#set spoolfile = "+INBOX"
#set postponed="Drafts"

#set header_cache=~/.mutt/cache/headers
#set message_cachedir=~/.mutt/cache/bodies
#set certificate_file=~/.mutt/certificates

#set move = no
#
##set mail_check=60           # check for new mail every 60 seconds
##set timeout=15
EOF
return 0
}

#################################################
function main {
#actorig=$@
#act="${actorig#+(* )}"
act=""

while getopts :d:s:io name ; do
	showdbg getopts:$name
	case $name in
		  d)  olddel=$OPTARG
			;;
		  s)  newdel=$OPTARG
			;;
		  i)  act=login
			;;
		  o)  act=logout
			;;
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
curl 'https://webauth-redirect.oracle.com/logout.html' -H 'Cookie: s_nr=1454581792067; ORASSO_AUTH_HINT=v1.0~20160205092735; ORA_UCM_INFO=3~B10F1856A28EB24AE040548C2D7068AF~Zhaoyong~Zhang~zhaoyong.zhang@oracle.com; s_cc=true; gpw_e24=no%20value; s_sq=oracledocs%3D%2526pid%253Ddocs%25253Aen-us%25253A%25252Fcd%25252Fe37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Fdocs.oracle.com%25252Fcd%25252FE37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%252523BABEJCBF%2526ot%253DA' -H 'Origin: https://webauth-redirect.oracle.com' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://webauth-redirect.oracle.com/logout.html' -H 'Connection: keep-alive' --data 'userStatus=1&err_flag=0&err_msg=' --compressed -v
;;
##########################################################
("login")
showdbg "show $act"
rm -f $tmp_pwd
getwifipwd.sh 2>&1 | tee $tmp_pwd
pwd=$(cat $tmp_pwd | grep Password | awk '{print $2}')
echo "password=$pwd" 
rm -f $tmp_pwd

curl 'https://webauth-redirect.oracle.com/login.html' --data "buttonClicked=4&redirect_url=www.baidu.com%2F&err_flag=0&username=guest&password=$pwd" --compressed --insecure -v
echo "pwd=$pwd"
;;
esac 
}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

