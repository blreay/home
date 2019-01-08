#!/bin/bash

#for i in $(find . -path "*CVS/Root"); do echo $i; echo ":ssh;username=zhaozhan;privatekey='D:\mydisk\tools\network\Telnet\putty\key-zzy\zzy01-private.ppk':zhaozhan@bjsrc.cn.oracle.com:/repos" > $i; done
#for i in $(find . -path "*CVS/Root"); do echo $i; echo ":ssh;username=zhaozhan;privatekey='/home/zhaozhan/.ssh/zzy01-private.ppk':zhaozhan@bjsrc.cn.oracle.com:/repos" > $i; done
#for i in $(find . -path "*CVS/Root"); do echo $i; echo ":pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos" > $i; done    

#AIX
#for i in $(find . -name "Root" |grep "CVS/Root"); do echo $i; echo ":ext:beadev@bjsrc.cn.oracle.com:/repos" > $i; done

#Linux
for i in $(find . -path "*CVS/Root"); do echo $i; echo ":ext:beadev@bjsrc.cn.oracle.com:/repos" > $i; done
