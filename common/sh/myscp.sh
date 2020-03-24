#!/bin/bash

#if [[ -z ${MYPWD} && ! -f ~/.ssh/id_rsa ]]; then
	#echo "Please export MYPWD(your password on object machine) at first"
	#exit 1
#fi

sshopt="-o ServerAliveCountMax=2 -o ServerAliveInterval=120 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa"

cmd="${@}"
#set -vx
case "${MYPWD}" in
	"") CMD="scp ${sshopt} ${cmd}" ;;
	*) CMD="remote-exec.sh \"scp ${cmd}\" $MYPWD" ;;
esac
echo ${CMD}
eval ${CMD}
