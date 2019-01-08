#!/bin/bash

#set -vx
[[ -z "$APP_HOME" ]] && export APP_HOME=$HOME
export PATH=$APP_HOME/mybox:$PATH
##################################################################
unzip -v >/dev/null 2>&1 \
&& { PATCHFILE=mybox.zip \
&& TMPFN="$APP_HOME/patch_$(date +'%Y%m%d_%H%M%S').zip" \
&& curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/patch/$PATCHFILE -o $TMPFN \
&& unzip -l $TMPFN \
&& cd $APP_HOME \
&& unzip -o $TMPFN \
&& echo "patch OK"; \
} || { PATCHFILE=mybox.tar \
&& TMPFN="$APP_HOME/patch_$(date +'%Y%m%d_%H%M%S').tar" \
&& curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/patch/$PATCHFILE -o $TMPFN \
&& tar tvf $TMPFN \
&& cd $APP_HOME \
&& tar xvf $TMPFN \
&& echo "patch OK"; \
}
####################################################################
#TELNET_MAP_HOST=10.182.74.189
TELNET_MAP_HOST=bej301738.cn.oracle.com
res=$(./mybox/dbclient -f -y -i ./mybox/privateKey.dropbear -l bcs ${TELNET_MAP_HOST} " \
typeset base=\$((18100+\${RANDOM}%500));
typeset retrymax=2000;
typeset retry=1;
typeset freeport=0;
portlist=\$(netstat -ant  |awk '{print \$4}' | egrep "^[0-2]" | awk -F: '{print \$2}' | sort | uniq | egrep \${base:0:2}); 
while [[ \$retry -lt \$retrymax ]]; do 
	echo "try \$retry/\$retrymax" >&2; 
	((retry++)); ((curport=\$base+\$retry)); 
	[[ \$portlist =~ \$curport ]] && continue; 
	freeport=\$curport && echo "freeport \$freeport" && break; 
done; 
[[ \$freeport -eq 0 ]] && echo "can NOT get free port" >&2; ")
echo "$res"
FREEPORT=$(echo $res | grep freeport | awk '{print $2}')
echo "FREEPORT=$FREEPORT"
####################################################################
TELNET_MAP_PORT=${FREEPORT:-18200}
TELNET_LOCAL_PORT=10923
MAP_FILE="/tmp/map.txt"
[[ "$1" == "my" ]] && LOGINCMD="$APP_HOME/mybox/mysshshell.sh" && TELNET_LOCAL_PORT=20923 && ${HOME}/mybox/busybox telnetd -l ${LOGINCMD:-/bin/bash} -p 7333
nohup ./mybox/busybox telnetd -l ${LOGINCMD:-/bin/bash} -p ${TELNET_LOCAL_PORT} >/dev/null 2>&1 </dev/null &
nohup ./mybox/dbclient -I 0 -K 99999 -y -g -i ./mybox/privateKey.dropbear -N -l bcs -o ExitOnForwardFailure=yes -p 22 -R ${TELNET_MAP_HOST}:${TELNET_MAP_PORT}:0.0.0.0:${TELNET_LOCAL_PORT}  ${TELNET_MAP_HOST} >/dev/null 2>&1 </dev/null &
PID=$!; echo "PID=$PID"; sleep 3
kill -0 $PID; RET=$?
ps -ef|egrep "(telnetd|dbclient)"
./mybox/dbclient -f -y -i ./mybox/privateKey.dropbear -l bcs ${TELNET_MAP_HOST} "echo ${TELNET_MAP_PORT} $(uname -n) $(date +'%Y%m%d_%H%M%S') >> ${MAP_FILE}"
[[ $RET -eq 0 ]] && echo -e "\nPlease run: telnet $TELNET_MAP_HOST $TELNET_MAP_PORT" || echo "ERROR occured"
####################################################################
