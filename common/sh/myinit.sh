#!/bin/ksh

typeset fflag=0
typeset exclude=",PATH,SHELL,TERM,LANG,MAIL,PS1,PS4,SHLVL,LOGNAME,CVS_RSH,SSH_ASKPASS,HOME,SSH_CONNECTION,MODULESHOME,DIR_TRASH,DEVPATH,LESSOPEN,NFS,DISPLAY,G_BROKEN_FILENAMES,{,},"

while getopts :f opt; do
	case $opt in
	(f) fflag=1;;
	(*) echo "usage: myinit.sh [-f]"; exit 1;;
	esac
done

for i in $(env|awk -F= '{print $1}'); do 
	echo $exclude | grep ",$i," >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo "unset $i"
		unset $i
	else
		echo "--------- ignore $i -----------"
	fi
done

export PATH=/bin:/usr/bin:/bin:/usr/sbin:/usr/local/bin
. $NFS/.bashrc

if [[ fflag -eq 1 ]]; then
	exec /bin/bash 
fi

