#!/bin/bash

OS=`uname`

unset DISPLAY

typeset cmd=$1

case "${cmd}" in
("")
	if [[ $OS == "Linux" ]]; then
		vncserver -geometry 1850x980  -IdleTimeout 0 -depth 24
	else
		vncserver -geometry 1850x980
	fi
	;;
("killall")
	while read line; do
		[[ -z "${line}" ]] && continue
		echo $line
		vncserver -kill ${line%% *} &
	done <<-EOF
	$(vncserver -list | egrep ^:)
EOF
	wait
	;;
esac


