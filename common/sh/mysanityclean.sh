#!/bin/bash
if [[ -z $USER ]]; then
    export USER=$(id|tr '()' '  '|awk  '{print $2}')
fi
if [[ -z $USER ]]; then
	echo "can NOT get USER id"
    exit 1
fi

ipck2.sh
#ps -ef|grep $USER|grep "runcase.sh"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "sanity.sh"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "tail -f"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "mi_make.sh"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "sanity_test.sh"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "artjesadmin"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "ARTJES"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "qmadmin"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "TMUSREVT"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "BBL"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "DBBL"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "BRIDGE"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "TMQUEUE"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "tee"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "TMS_QM"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "pdksh "|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "\[pdksh\]"|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "ksh "|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "db2bp "|tee|awk '{print $2}'|xargs -I {} kill -9 {}
#ps -ef|grep $USER|grep "timeoutmonitor"|tee|awk '{print $2}'|xargs -I {} kill -9 {}

killpattern="(citsort |runcase.sh|sanity.sh|tail -f|mi_make.sh|sanity_test.sh|artjesadmin|ARTJES|qmadmin|tmboot|TMUSREVT|BBL|DBBL|BRIDGE|TMQUEUE|tee|TMS_QM|pdksh |\[pdksh\]|ksh |db2bp |timeoutmonitor|ARTAccessManagement|JCLExecutor|ARTCOBRUN|batch.sh|cvs co art/sanity/batchrt)"
#ps -ef|grep $USER|egrep "${killpattern}" 
ps -ef|grep $USER|egrep "${killpattern}" |awk '{print $2}'|xargs -I {} kill -9 {}
killpattern="(runcase.sh|sanity.sh|tail|mi_make.sh|sanity_test.sh|artjesadmin|ARTJES|TMS_ORA|TMD_UDB|ARTSTRN|ARTDPL|ARTTCPL|ARTTCPH|ARTADM|ARTTSQ|ARTCNX|environment_for_ingram|qmadmin|TMUSREVT|BBL|DBBL|TMQUEUE|tee|TMS_QM|pdksh|\[pdksh\]|ksh|db2bp|defunct|timeoutmonitor|job_run)"
ps -ef|grep $USER|egrep "${killpattern}" |awk '{print $2}'|xargs -I {} kill -9 {}
ps -ef|grep $USER 
