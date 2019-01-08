#!/bin/bash

typeset g_port_forward=19001
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
cat - > $fn <<-\EOF
set from = "zhaoyong.zhang@oracle.com"
set realname = "zzy"
set imap_user = "zhaoyong.zhang@oracle.com"
set imap_pass = "AQG9aPQG001"
set use_from = yes

#set mbox = +Inbox
#set folder = "imaps://$imap_user@stbeehive.oracle.com:993"

set smtp_url = "smtps://$imap_user@stbeehive.oracle.com:465"
set smtp_pass = "$imap_pass"
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
#act="${actorig#+(* )}"
act="forward"
OPTINT=1

while getopts :ts:io name ; do
	showdbg zzy:$name
	case $name in
		  d)  olddel=$OPTARG
			;;
		  s)  newdel=$OPTARG
			;;
		  i)  act=login
			;;
		  t)  act=test
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

case ${act} in
("")
	show_usage
	return 1
	;;
##########################################################
("forward")
sudo ssh -4 -f -N -D 0.0.0.0:$g_port_forward -g zhaozhan@10.182.54.32
netstat -an|grep $g_port_forward
;;
##########################################################
("test")
showdbg "show $act"
#curl -v --socks localhost:$g_port_forward http://ifconfig.me
curl -v --socks localhost:$g_port_forward http://www.baidu.com -o /tmp/.curl.1
/bin/rm -rf /tmp/.curl.1
echo
;;
esac 
}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

