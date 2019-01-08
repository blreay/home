#!/bin/ksh

set -A inslist batch001 batch002 batch003 batch004 batch005 batch006 test

function stopall {
for ins in ${inslist[*]}; do
        export ORACLE_SID=$ins
        echo "shutdown" | sqlplus / as sysdba
done
}

lsnrctl stop
rm -f $ORACLE_HOME/dbs/lk*

myps.sh |grep batch00|awk '{print $2}'|xargs kill -9
myps.sh |grep ora_|awk '{print $2}'|xargs kill -9

for ins in ${inslist[*]}; do
        export ORACLE_SID=$ins
        echo "startup"    | sqlplus / as sysdba
done

lsnrctl start

