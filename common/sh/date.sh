#!/usr/bin/bash

TSP_MSEC=`perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"'`
MSEC=`echo $TSP_MSEC | cut -c11-13`

TSP=`date +%d.%m.20%y" "%H:%M:%S.$MSEC`
echo $TSP

