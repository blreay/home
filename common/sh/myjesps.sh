#!/bin/ksh
myps.sh |egrep "( BBL|DBBL|tlisten| ART| TM|pdksh|mksh|runb|artjesadmin|LMS|defunct|ART|JCLExecutor)"|egrep -v egrep|sort
