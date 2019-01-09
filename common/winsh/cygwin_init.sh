#!/bin/bash
####################################################
#
# initialize CYGIN environment
#
####################################################


## some command can't be used, such as ROUTE, ARP, becasue they are upper-case
## create link /bin for them
cd /bin
for i in $(/bin/ls -l /cygdrive/c/Windows/System32/*.EXE | awk '{print $NF}' | sed 's/windows/Windows/g'); do
	echo $i; 
	t=$(echo $i | awk -F [/] '{print $NF}'); t=${t,,}; t=${t%.exe*}; 
	echo $t; 
	ln -svnf $i $t; 
done
