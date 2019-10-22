#!/bin/bash

source $SH/mycommon.sh

typeset g_port_forward=19002
g_appname=${0##*/}
DBG "g_appname=$g_appname"
##########################################

function show_usage {
	ERR "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] acting"
    ERR "        -d : specify the delimiter"
    ERR "        -s : specify the new delimiter"
}
#################################################
function my_entry {
#act="${actorig#+(* )}"
#act="forward"
unset OPTIND
while getopts :ts:p:r:io name ; do
	DBG zzy:$name
	case $name in
		  p)  g_port_forward=$OPTARG ;;
		  r)  remote_ssh_info=$OPTARG ;;
		  d)  olddel=$OPTARG ;;
		  s)  newdel=$OPTARG ;;
		  i)  act=login ;;
		  t)  act=test ;;
		  \?) echo "invalid option $name"; show_usage exit 0 ;;
	esac
	unset OPTARG
done
DBG "olddel=$olddel newdel=$newdel"

shift $(($OPTIND -1))
DBG " shift $(($OPTIND -1))"
act=$1
DBG "act=${act}"
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
(ssh_svc_forward|git_rf)
#CMD="ssh -4 -f -N -g -R 0.0.0.0:${g_port_forward}:0.0.0.0:22 root@139.196.80.41"
CMD="myssh.sh -4 -f -N -g -R 0.0.0.0:${g_port_forward}:0.0.0.0:22 ${remote_ssh_info}"
MSG ${CMD}
eval ${CMD}
netstat -an|grep $g_port_forward
;;
##########################################################
("test")
DBG "show $act"
#curl -v --socks localhost:$g_port_forward http://ifconfig.me
curl -v --socks localhost:$g_port_forward http://www.baidu.com -o /tmp/.curl.1
/bin/rm -rf /tmp/.curl.1
echo
;;
esac
}

###########################################
main ${@:+"$@"}

