#!/bin/ksh

set -A inslist batch001 batch002 batch003 batch004 batch005 batch006 test

function show_usage {
	echo "Usage: ${0##*/} [-r] [-g <GeneartionNumber>] <GDG_Base>"
}
function stopall {
	for ins in ${inslist[*]}; do
			export ORACLE_SID=$ins
			echo "shutdown" | sqlplus / as sysdba
	done

	lsnrctl stop
	rm -f $ORACLE_HOME/dbs/lk*

	myps.sh |grep batch00|awk '{print $2}'|xargs kill -9
	myps.sh |grep ora_|awk '{print $2}'|xargs kill -9
}

function startall {
	for ins in ${inslist[*]}; do
			export ORACLE_SID=$ins
			echo "startup"    | sqlplus / as sysdba
	done 
	lsnrctl start
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
