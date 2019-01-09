#!/bin/bash

##NOTE: must use "windows command prompt: CMD.exe" and run "adb shell" then run "getevent" 
##   to capture the event list in shell of android, need to do screen txt copy from command window.
##   and don't use I/O redirect, otherwise because have to use ctrl-C to stop capture, 
##   becasue of line buffer and full buffer, the contents maybe incomplete
##   adb shell getevent can't work also

function getit {
 cat evt.cap | dos2unix | grep -e "^/dev/input" | awk '{printf("%s %s %s\n", $2,$3,$4)}' |  { while read a b d; do echo "$((16#$a)) $((16#$b)) $((16#$d))"; done > evt.in.10; }
}

trap 'getit' EXIT

#rm evt.in.10 evt.cap
#adb shell getevent > evt.cap
