#!/bin/bash

################################################################
typeset KEYFILE=/tmp/.zkey.lock.$USER
typeset MYUSER=zhaozhan
typeset MYSVR=bej301738.cn.oracle.com
typeset MYPCPORT=30022
################################################################

[[ ! -f ${KEYFILE} ]] && {
cat - <<\EOF > ${KEYFILE}
KEY IS DELETED FOR SECURITY ISSUE REPORTED BY GITHUB
EOF
chmod 600 ${KEYFILE}
}

eval `ssh-agent -s`
ssh-add ${KEYFILE}
export MYNFS=$MYUSER@$MYSVR:/nfs/users/zhaozhan
export MYSHR=$MYNFS/share
export MYSCP="scp -P $MYPCPORT -o StrictHostKeyChecking=no $MYUSER@$MYSVR:/shr"
export MYPCSCP="function MYPCSCP { port=30022; shr=zhaozhan@bej301738.cn.oracle.com:/shr; f1=; f2=;  if [[ \$1 == 'from' ]]; then shift 1; f1=\$1; f2=\$2;	echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \$shr/\${f1} \${f2}; set +vx;else f1=\$1; f2=\$2; echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \${f1} \$shr/\${f2}; set +vx;fi; }; MYPCSCP " 
export MYNFSCP="function MYNFSCP { port=22; shr=zhaozhan@bej301738.cn.oracle.com:/nfs/users/zhaozhan/share; f1=; f2=;  if [[ \$1 == 'from' ]]; then shift 1; f1=\$1; f2=\$2;	echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \$shr/\${f1} \${f2}; set +vx;else f1=\$1; f2=\$2; echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \${f1} \$shr/\${f2}; set +vx;fi; }; MYNFSCP "

echo "\$0=$0"

## open shell
if [[ ! "$0" =~ ^(/bin/bash|/bin/sh|-bash|bash)$ ]]; then
	echo "Enter shell ($SHELL) with ssh auto authentication"
	$SHELL
	## clean
	ssh-agent -k
	rm -f "${KEYFILE}"
	exit
fi
