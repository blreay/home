#!/bin/bash

# forward all the port needed for root ftp server on android

typeset portlist=${1:-"10030 10031 10032"}

for i in $portlist; do
	echo "run: adb forward tcp:$i tcp:$i"
	adb forward tcp:$i tcp:$i
done

