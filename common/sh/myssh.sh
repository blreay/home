#!/bin/bash

function show_usage {
	echo "Usage: ${0##*/} user@hostname"
}

#set -vh
#########################################################################
## Check Paramter ##
:<<EOF
while getopts :d:g:m: name; do
	case $name in
	  d)  use_db_direct=1; export g_MaxGen=$OPTARG;;
	  g)  gflag=1; maxgen=$OPTARG;;
	  m)  mflag=1; gennumlist=$OPTARG ;;
	  ?)  show_usage; echo aaa; exit 1 ;;
	esac
done

if [[ -z $MYPWD ]]; then
	echo "MYPWD is not set"
	exit 1
fi
EOF

#set -vx
cmd="${@}"
#remote-exec.sh """$cmd""" $MYPWD
#./ssh2.sh """ssh $cmd""" $MYPWD
#remote-ssh.sh """ssh $cmd""" "IGNORE"
# -x  Disables X11 forwarding.
# -Y  Enables trusted X11 forwarding.  Trusted X11 forwardings are not subjected to the X11 SECURITY extension controls.

sshopt="-o TCPKeepAlive=yes -o ServerAliveCountMax=2 -o ServerAliveInterval=120 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -Y -t"

CMD="ssh ${sshopt} $@"
echo "${CMD}" >&2
eval "${CMD}"
