#!/bin/bash

#set -vx
function DBG {
	[[ ! "${MYDBG}" =~ "DEBUG|debug" ]] && return 0
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
	printf "%s" "${msg}"
	return 0
} 
function LOG {
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
	printf "%s" "${msg}"
	return 0
} 

function ERR {
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}"
	printf "%s" "${msg}"
	return 0
} 

function send_cmd {
	typeset session=$1
	typeset cmd="$2"
	echo "session=$session cmd=$cmd"
	#for _window in $(tmux list-windows -t $session -F "#{window_id},#{window_name}"); do
	for win in $(tmux list-windows -t $session -F "#{window_id},#{window_name}"); do
		_window=${win%%,*}
		_name=${win##*,}
		[[ "${_name}" == "my" && ${g_force} -eq 0 ]] && echo "ignore my working windows" && continue
		for _pane in $(tmux list-panes -F '#{pane_id}' -t ${_window}); do 
			#echo "window.pane: ${_window}.${_pane} window.name ${_name}"
			CMD="tmux send-keys -t ${_pane} \"${cmd}\" C-m"
			echo "${CMD}"
			eval "${CMD}"
		done
	done
}

function main {
	##########################
	typeset sendcmd=""
	typeset g_detach=0
	typeset g_force=0
	unset OPTIND
	while getopts :dfc: ch; do
		case $ch in
		c) sendcmd="$OPTARG"; echo "sendcmd=$sendcmd";;
		d) g_detach=1; echo "don't attach";;
		f) g_force=1; echo "force mode";;
		?) echo "unknown option" && return 1;;
		esac
	done
	shift $((OPTIND-1))
	##########################

	typeset session=${1:-"zzy01"}   # session name
	#typeset main_win_name="luit_bash"
	typeset main_win_name="main"
	typeset second_win_name="working"
	#typeset cmd_win_name="luit_cmd"
	typeset cmd_win_name="win_cmd"
	typeset cmd=
	typeset mybash="/bin/bash"

	## send cmd mode
	if [[ -n "${sendcmd}" ]]; then
		send_cmd ${session} "${sendcmd}"
		return 0
	fi

	if [[ "$(uname)" =~ CYGWIN ]]; then
		cmd="tmux"
	elif [[ "$(uname)" =~ SunOS ]]; then
		export TERM="putty-256color"
		cmd="tmux"
	else
		cmd="tmux -2u"
	fi 
	DBG "cmd=$cmd"

	typeset loopbash="while true; do $mybash; done"
	typeset loopgbkbash="while true; do luit -encoding gbk $mybash; done"
	#typeset loopgbkcmd="while true; do luit -encoding gbk cmd; done"
	typeset loopcmd="while true; do rlwrap cmd; done"

	if [ -z "${cmd}" ]; then
		echo "You need to install tmux."
		return 1
	fi

	${cmd} has -t ${session} 

		if [ $? != 0 ]; then
			DBG "create new session"
			if [[ "$(uname)" =~ CYGWIN ]]; then
			#${cmd} new -d -n "$main_win_name" -s ${session} "${loopgbkbash}"
			${cmd} new -d -n "$main_win_name" -s ${session} "${loopbash}"
			#${cmd} splitw -h -p 35 -t ${session} "bash -c \"monitor_network.sh; ${loopgbkbash}\""
			#${cmd} splitw -h -p 35 -t ${session} "while true; do monitor_network.sh; ${loopgbkbash}; done"
			${cmd} splitw -h -p 35 -t ${session}:${main_win_name} "${loopbash}"
			${cmd} splitw -v -p 50 -t ${session}:${main_win_name}.1 "${loopbash}"
			${cmd} neww -d -n $second_win_name -t ${session} "${loopbash}"
			${cmd} neww -d -t ${session} "${loopbash}"
			${cmd} neww -d -t ${session} "${loopbash}"
			${cmd} neww -d -t ${session} "${loopbash}"
			${cmd} neww -d -t ${session} "${loopbash}"
			${cmd} neww -d -n $cmd_win_name -t ${session} "${loopcmd}"
			#select the first window
			#${cmd} selectw -t ${session}:0
			#select the first pane of first window
			#${cmd} select-pane -t ${session}.0
			#select the second window
			${cmd} select-window -t ${session}:1
			#:<<EOF
			#${cmd} send-keys -t ${session}:${main_win_name}.0 'cd ~; locale; s; ipconfig; cmd2remote.sh -h bej301712 -f /nfs/users/zhaozhan/mypc.txt -c "ipconfig;echo record ip"' C-m C-m
			${cmd} send-keys -t ${session}:${main_win_name}.0 'cd ~; locale; s; ipconfig;' C-m C-m
			#${cmd} send-keys -t ${session}:${main_win_name}.0 'cd ~; ssh -f -g -N -R 30022:localhost:22 bej301738.cn.oracle.com' C-m C-m
			#${cmd} send-keys -t ${session}:${main_win_name}.0 'cd ~; ssh -f -g -N -R 33389:localhost:3389 bej301738.cn.oracle.com' C-m C-m
			#${cmd} send-keys -t ${session}:${main_win_name}.1 'cd $SH; monitor_network.sh always' C-m 
			${cmd} send-keys -t ${session}:${main_win_name}.2 'cd $SH; adbmonitor.sh.NOTEXIST' C-m 
			## show unicode char
			${cmd} send-keys -t ${session}:${second_win_name}.0 'cd ~; set_cn; locale; s' C-m 
			## for command prompt
			${cmd} send-keys -t ${session}:${cmd_win_name}.0 'ipconfig' C-m 
#EOF
		else 
			#${cmd} new -d -n bash -s ${session} "${loopbash}"
			${cmd} new -d -s ${session} "${loopbash}"
			for((i=1;i<9;i++)); do 
				#${cmd} neww -d -n bash -t ${session} "${loopbash}"
				${cmd} neww -d -t ${session} "${loopbash}"
			done
			${cmd} neww -d -n "my" -t ${session} "${loopbash}"
		fi
	fi

	[[ ${g_detach} -eq 0 ]] && ${cmd} att -t ${session}
}

###############################################
main "${@}"
