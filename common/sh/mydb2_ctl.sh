#!/bin/bash

# this is for slc03kuw.us.oracle.com

#set -A inslist batch001 batch002 batch003 batch004 batch005 batch006 test
#this is ksh syntax
#set -A inslist db2inst1 db2test1 db2test2 db2test3 db2test5 db2test4 db2test6

#this is bash syntax
declare -a inslist=(db2inst1 db2test1 db2test2 db2test3 db2test5 db2test4 db2test6)

#set password
declare -A pwddb2=(
[db2inst1]=db2inst1
[db2test1]=nodb2test1
[db2test2]=nodb2test2
[db2test3]=nodb2test3
[db2test4]=nodb2test4
[db2test5]=nodb2test5
[db2test6]=nodb2test6
)

function show_usage {
	echo "Usage: ${0##*/} [-r] [-g <GeneartionNumber>] <GDG_Base>"
}
function stopall {
}

function startall {
	for i in ${inslist[*]}; do
		echo $i

		# if sudo can be used:
		#echo "cd ~; . ./sqllib/profile.env; db2 db2start" | sudo mysu - $i

		# use su to handle
		#echo "cd ~; . ./sqllib/profile.env; db2 db2start" | su - $i

		#use expect to handle
		remote-exec.sh "sh -c \"echo \\\" cd ~; . ./sqllib/profile.env; db2 db2start \\\"| su - $i\"" ${pwddb2[$i]}
	done
}

function cleanall {
	rm -f $ORACLE_HOME/dbs/lk* 
	myps.sh |grep batch00|awk '{print $2}'|xargs kill -9
	myps.sh |grep ora_|awk '{print $2}'|xargs kill -9
}

#set -vh
#########################################################################
## Check Paramter ##
while getopts :d:g:m: name; do
	case $name in
	  d)  use_db_direct=1; export g_MaxGen=$OPTARG;;
	  g)  gflag=1; maxgen=$OPTARG;;
	  m)  mflag=1; gennumlist=$OPTARG ;;
	  ?)  show_usage; echo aaa; exit 1 ;;
	esac
done

case $1 in
start) startall;
	break;;
stop) stopall;
	break;;
restart) stoptall;
	startall;
	break;;
*)  echo "invalid command: $1"
	exit 1;;
esac
