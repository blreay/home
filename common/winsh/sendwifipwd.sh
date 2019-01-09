#!/bin/bash

#####################################
## NEED to export following environment variables at first
##############################################
## updated by zhaozhan, 2017/06/13
## added   by zhaozhan, 2016/02/15

## must set LC_ALL=c or LC_ALL=zh_CN.gbk, because all windows command output GBK charset, 
## grep may get "binary data match" result
export LC_ALL=C

false && {
export MYMAILADDR="blreay@139.com"
export SSO_WIFI_PWD_URL="https://gmp.oracle.com/captcha/files/airespace_pwd_apac.txt"

export SSO_NAME="zhaoyong.zhang@oracle.com"
export SSO_PWD=""
export SSO_MAIL_ADDR="$SSO_NAME"
export SSO_MAIL_NAME="zzy"
export SSO_SMTP_ADDR="stbeehive.oracle.com"
export SSO_SMTP_PORT=465

export SINA_NAME="blreay@sina.com"
export SINA_PWD=""
export SINA_MAIL_ADDR="$SINA_NAME"
export SINA_MAIL_NAME="zzy"
export SINA_SMTP_ADDR="smpt.sina.com"
export SINA_SMTP_PORT=465
} 
##############################################################

typeset BYCORP=0
typeset BYSINA=1
typeset mail_to=${MYMAILADDR}
typeset mail_title="test"
typeset muttrc=/tmp/muttrc
typeset muttrc_sina=/tmp/muttrc_sina
typeset tmp_file=/tmp/curl.sendpwd
typeset MYWIFIFILE=${MYWIFIFILE:-$HOME/wifiinfo.txt}
##########################################

function show_usage {
	showerr "Usage: ${g_appname##*/} [-i] [-s SMTPsvr]"
    showerr "        -i : read pwd from $MYWIFIFILE but not fetch it from gmp server"
    showerr "        -s : set SMTP server(sina|corp|all)"
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
	echo "[$(date +'%Y%m%d_%H%M%S')]" ${@:+"$@"} >&2
}
function showmsg {
	echo "[$(date +'%Y%m%d_%H%M%S')] ${@:+"$@"}" >&1
}

###################################################
function gen_mutt_rc {

[[ -z $1 ]] && showerr "no filename for muttrc" && return 1

typeset fn=$1
cat - > $fn <<-EOF
unset ssl_verify_host
#set copy=no
set copy=yes

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

function gen_mutt_rc_sina {

[[ -z $1 ]] && showerr "no filename for muttrc" && return 1

typeset fn=$1
cat - > $fn <<-EOF
unset ssl_verify_host 
#set copy=no
set copy=yes
set from = "$SINA_MAIL_ADDR"
set realname = "$SINA_MAIL_NAME"
set imap_user = "$SINA_NAME"
set imap_pass = "$SINA_PWD"
set use_from = yes

#set mbox = +Inbox
#set folder = "imaps://\$imap_user@$SINA_SMTP_ADDR:993"

set smtp_url = "smtps://\$imap_user@$SINA_SMTP_ADDR:$SINA_SMTP_PORT"
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

function remove_mutt_rc {
	typeset muttrc=$1
	[[ -f $muttrc ]] && /bin/rm -rf $muttrc
}

#################################################
function main_sendpwd {
typeset use_internal_file=0
typeset server=

unset OPTIND
while getopts :d:s:ih name ; do
	case $name in
		  d)  olddel=$OPTARG;;
		  s)  server=$OPTARG;;
		  i)  use_internal_file=1;;
		  h)  show_usage; return 0;;
		  \?) showerr "invalid option $name"; show_usage; return 0 ;;
	esac
	unset OPTARG
done
showdbg "olddel=$olddel server=$server"

case $server in
("sina")   BYSINA=1 && BYCORP=0;;
("corp")   BYSINA=0 && BYCORP=1;;
("all")    BYSINA=1 && BYCORP=1;;
("")       BYSINA=1 && BYCORP=0;;
(*) showerr "invalid SMTP server: $server" && return 1;;
esac

shift $(($OPTIND -1))
str=$1

if [[ $use_internal_file -eq 1 ]]; then
	showmsg "read wifi password from $MYWIFIFILE"
else
	showmsg "fetch wifi password from web server"
	getwifipwd.sh 2>&1 | tee $MYWIFIFILE
fi

pwd=$(cat $MYWIFIFILE | awk '/Password:/{print $2}') 
showmsg "password=$pwd  [passwdpre=$pwdpre]"

[[ -f $tmp_file ]] && /bin/rm -f $tmp_file

## password is NULL
[[ -z $pwd ]] &&  { showmsg "ERROR: password is empty" && return 1; }

## update pre password
## pwdpre is a global variable, as this script will be run with "source" in the parent script.
[[ "$pwd" == "$pwdpre" ]] && showmsg "This passwd had been sent: $pwd, do nothing" && return 0

typeset -i ret=1

[[ $BYSINA -eq 1 ]] && {
	## generate rc file for mutt
	gen_mutt_rc_sina ${muttrc_sina} || { showerr "can't create muttrc ${muttrc_sina}" && return 1; }
	## avoid error "can't lock ~/sent"
	[[ -f ~/sent.lock ]] && /bin/rm -f ~/sent.lock
	#send pwd
	[[ -n "$pwd" ]] && echo "$pwd" | mutt -F ${muttrc_sina} -s $mail_title $mail_to && pwdpre="${pwd:-$pwdpre}" && showmsg "[sina] set pwdpre to $pwdpre" && ret=0
	showmsg "ret=$ret  [passwdpre=$pwdpre]"
	## delete muttrc
	remove_mutt_rc ${muttrc_sina}

	## if failed, try to send with corporation SMTP server
	[[ $ret -ne 0 ]] && [[ -z "$server" ]] && showmsg "[sina] send failed, try other SMTP server" && BYCORP=1
}

[[ $BYCORP -eq 1 ]] && {
	## generate rc file for mutt
	gen_mutt_rc $muttrc || { showerr "can't create muttrc $muttrc" && return 1; }
	## avoid error "can't lock ~/sent"
	[[ -f ~/sent.lock ]] && /bin/rm -f ~/sent.lock
	#send pwd
	#[[ -n $pwd ]] && echo "$pwd" | mutt -F ${muttrc}      -s $mail_title $mail_to
	[[ -n "$pwd" ]] && echo "$pwd" | mutt -F ${muttrc} -s $mail_title $mail_to && pwdpre="${pwd:-$pwdpre}" && showmsg "[corp] set pwdpre to $pwdpre" && ret=0
	## delete muttrc
	remove_mutt_rc ${muttrc}
}
return $ret 
}

###########################################
g_appname=${0##*/}
showdbg "g_appname=${g_appname} [$@]"
echo "g_appname=${g_appname} [$@]"
main_sendpwd "${@:+"$@"}"

