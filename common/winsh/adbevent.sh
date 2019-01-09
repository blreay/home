#!/bin/bash

typeset src=$1
typeset dst=$2
[[ -z $src ]] || [[ -z $dst ]] && { echo "usage: $0 src dst"; exit -1; }
set -vx
adb shell getevent /dev/input/event2 > $src
dos2unix $src
cat $src | sed 's/^/sendevent \/dev\/input\/event2 /g;s/://g;' | awk '{ printf("%s %s %s %d %d\n", $1, $2, $3, strtonum("0x"$4), strtonum("0x"$5)) }' > $dst
echo end
