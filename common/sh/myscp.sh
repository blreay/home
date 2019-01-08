#!/bin/ksh

if [[ -z ${MYPWD} && ! -f ~/.ssh/id_rsa ]]; then
	echo "Please export MYPWD(your password on object machine) at first"
	exit 1
fi

cmd="${@}"
#set -vx
case "$MYPSD" in
	"") CMD="scp -i ~/.ssh/id_rsa ${cmd}" ;; 
	*) CMD="remote-exec.sh \"scp ${cmd}\" $MYPWD" ;;
esac
echo ${CMD}
eval ${CMD}
