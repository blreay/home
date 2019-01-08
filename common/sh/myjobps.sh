#!/bin/ksh
myps.sh |egrep "( ARTAccessManagement|JCLExecutor)"|egrep -v egrep|sort
