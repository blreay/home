#!/bin/bash

typeset mail_to=${MYMAILADDR}
typeset mail_title="test"
typeset muttrc=/tmp/muttrc
typeset tmp_file=/tmp/curl.sendpwd
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

function remove_mutt_rc {
	[[ -f $muttrc ]] && /bin/rm -rf $muttrc
}

#################################################
function main {
#strorig=$@
#str="${strorig#+(* )}"

while getopts :d:s: name ; do
	showdbg zzy:$name
	case $name in
		  d)  olddel=$OPTARG
			;;
		  s)  newdel=$OPTARG
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
str=$1
str="aa"
#set -vx

case ${str} in
("")
	show_usage
	return 1
	;;
(*)
	showdbg "show $str"
	echo $str|tr "$olddel" "$newdel"
	;;
esac 

## generate rc file for mutt
gen_mutt_rc $muttrc || { showerr "can't create muttrc $muttrc" && return 1; }

#wifilogin.sh
getwifipwd.sh | tee $tmp_file
pwd=$(cat $tmp_file | grep Password | awk '{print $2}')
echo "password=$pwd"
[[ -f $tmp_file ]] && /bin/rm -f $tmp_file

#send pwd
echo "$pwd" | mutt -F $muttrc -s $mail_title $mail_to

## delete muttrc
remove_mutt_rc
}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

