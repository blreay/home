#while read a b c; do echo $a $b $c; sendevent /dev/input/event2 $((0x$a)) $((0x$b)) $((0x$c)); done < /storage/sdcard1/code.txt
#while read a b c; do sendevent /dev/input/event2 $((0x$a)) $((0x$b)) $((0x$c)); done < /storage/sdcard1/code.txt
sendevent /dev/input/event2 0001 330 1
sendevent /dev/input/event2 0003 48 20
sendevent /dev/input/event2 0003 53 346
sendevent /dev/input/event2 0003 54 694
sendevent /dev/input/event2 0003 57 0
sendevent /dev/input/event2 0000 2 0
sendevent /dev/input/event2 0000 0 0
sendevent /dev/input/event2 0003 48 20
sendevent /dev/input/event2 0003 53 571
sendevent /dev/input/event2 0003 54 717
sendevent /dev/input/event2 0003 57 0
sendevent /dev/input/event2 0000 2 0
sendevent /dev/input/event2 0000 0 0
#This point is mandatory
sendevent /dev/input/event2 0003 48 20
sendevent /dev/input/event2 0003 53 506
sendevent /dev/input/event2 0003 54 828
sendevent /dev/input/event2 0003 57 0
sendevent /dev/input/event2 0000 2 0
sendevent /dev/input/event2 0000 0 0
sendevent /dev/input/event2 0003 48 20
sendevent /dev/input/event2 0003 53 349
sendevent /dev/input/event2 0003 54 872
sendevent /dev/input/event2 0003 57 0
sendevent /dev/input/event2 0000 2 0
sendevent /dev/input/event2 0000 0 0
sendevent /dev/input/event2 0001 330 0
sendevent /dev/input/event2 0000 2 0
sendevent /dev/input/event2 0000 0 0
