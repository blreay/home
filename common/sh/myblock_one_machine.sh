#!/bin/ksh

function usage {
	echo "Usage: ${g_appname##*/} [-u] machine_name" 
}

function block_one_machine {
        addr=$1
        iptables -A OUTPUT -p all -d ${addr} -j DROP
        iptables -A INPUT  -p all -s ${addr} -j DROP
}
function unblock_one_machine {
        addr=$1
        iptables -D OUTPUT -p all -d ${addr} -j DROP
        iptables -D INPUT  -p all -s ${addr} -j DROP
        #iptables -D OUTPUT -p tcp -d ${addr} -j DROP
        #iptables -D INPUT  -p tcp -s ${addr} -j DROP
}

##################################################
g_appname=$0
unblock=0
while getopts :u ch; do
	case $ch in
	u) unblock=1
	   shift 1
	   echo "unblock mode"
	   ;;
	h) usage; exit 0;;
	?) usage; exit 1;;
	esac 
done

addr=$1 
echo "addr=$addr"
if [[ -z $addr ]]; then
	usage
	exit 1
fi
#exit 0;
if [[ unblock -eq 1 ]]; then
	unblock_one_machine "${addr}"
else
	block_one_machine "${addr}"
fi
