#!/bin/sh 

function showdbg {
	if [[ -n "$MYDBG" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}" >&2
}
function showmsg {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}"
}

function myusage {
cat - <<EOF
$0 <pid> [test|all]
  test: just show the process tree
   all: kill the root process <pid> also
EOF
}

# to kill process tree identified by PidRunning
#set -vx
typeset PidRunning=$1
typeset act=$2

case ${PidRunning}${act} in
-h|help) myusage; exit 0;;
esac

kill -0 ${PidRunning} 2>/dev/null
[[ $? -ne 0 ]] && echo "process: $PidRunning is not running" && exit 1

typeset -i mt_RetryKillMax=1
typeset -i i=1

(( i=1 ))
while [ ${i} -le ${mt_RetryKillMax} ]; do
	#echo "###"
    #mt_Action="$(ps -ef | awk '{printf("%s %s %s\n", $2, $3, $NF)}' | egrep -v "(cps -ef|awk -v MONPID|grep -v|killpstree)" | 
    mt_Action="$(procps -ef | egrep -v "(cps -ef|awk -v MONPID|grep -v|killpstree)" | 
    awk -v MONPID="${PidRunning}" '
        {
            pchild[$3]=pchild[$3]" "$2;l[$2]=$0;
            if ($2==MONPID && writeflag!=1) {printf("%d:%s\n", MONPID, $0); writeflag=1;};
        }
        function f(pid) {
            first=0
            last =0
            queue[last++]=pid
            while (first != last+1) {
                currentpid=queue[first++]
                n=split(pchild[currentpid],t," ")
                for (i=1;i<=n;i++) {
                    if (t[i] != ""){
                        queue[last++]=t[i]
                }
            }
            if (currentpid!=MONPID && currentpid!="" ) { printf("%d:%s\n", currentpid, l[currentpid]) }
        }
        }
        END {
            process_list=f(MONPID)
        }')"

    if [[ ${mt_Action} = "" ]]; then
        mt_Action=${PidRunning}
    fi

	#echo "mt_Action="
	echo "${mt_Action}"
	[[ "${act}" == "test" ]] && exit 0

    while read mt_process_to_kill; do
        if [[ X${mt_process_to_kill} = X ]]; then
            continue
        fi
        mt_pid_to_kill=${mt_process_to_kill%%:*}
		[[ "$mt_pid_to_kill" == "$PidRunning" && "${act}" != "all" ]] && showdbg "don't kill root process $PidRunning" && continue 
		[[ "$mt_pid_to_kill" == "$$" ]] && showdbg "don't kill self $$" && continue 
		echo "$mt_process_to_kill"
		#procps -ef |grep $mt_pid_to_kill
        kill -0 ${mt_pid_to_kill} 2>/dev/null
        if [[ $? -eq 0 ]]; then
           # process still running
        	kill -9 ${mt_pid_to_kill} 2>/dev/null
			:	
        fi
    done <<-end_of_read
    ${mt_Action}
end_of_read
                
    #check if the JOB main process has been killed
    kill -0 ${PidRunning} 2>/dev/null
    if [[ $? -eq 0 ]]; then
        #JOB main process has NOT been killed, retry
        i=`expr ${i} + 1`
        continue
    else
        break
    fi
done


