#!/bin/bash
###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo
shopt -s extdebug

###############################################
# global variables
typeset g_appname
##############################################
function DBG {
    [[ "${MYDBG^^}" != "DEBUG" ]] && return 0
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}" >&2
}
function LOG {
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
}
function ERR {
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}" >&2
}
function WARN {
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "WARN: ${arg}" >&2
}
function MSG {
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "%s\n" "${arg}"
}
##############################################
alias BCS_CHK_RC0='{
    #### function check RC Block Begin #####
    RET=$?
    if [[ ${RET} -ne 0 ]]; then
        MSG=$(cat -); ERR "${MSG}, RET=${RET}"; return "${RET}"
    fi
    #### function check RC Block End #####
}<<<'
alias BCS_CHK_ACT_RC0='{
    #### function check RC Block Begin #####
    RET=$?; INPUTSTR=$(cat -); MSG="${INPUTSTR%%&&&*}"; ACT=""
    [[ "${MSG}" != "${INPUTSTR}" ]] && ACT="${INPUTSTR##*&&&}"
    NGACT="${ACT%%|||*}"; OKACG=""
    [[ "${NGACT}" != "${ACT}" ]] && OKACG="${ACT##*|||}"
    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"
        ERR "${MSG}, RET=${RET}"
        return ${RET}
    else
        eval "${OKACT}"
    fi
    #### function check RC Block End #####
}<<<'
alias BCS_WARN_RC0='{
    #### function check RC Block Begin #####
    RET=$?
    if [[ ${RET} -ne 0 ]]; then
        MSG=$(cat -)
        WARN "${MSG}, RET=${RET}"
    fi
    #### function check RC Block End #####
}<<<'
alias BCS_WARN_ACT_RC0='{
    #### function check RC Block Begin #####
    RET=$?; INPUTSTR=$(cat -); MSG="${INPUTSTR%%&&&*}"; ACT=""
    [[ "${MSG}" != "${INPUTSTR}" ]] && ACT="${INPUTSTR##*&&&}"
    NGACT="${ACT%%|||*}"; OKACG=""
    [[ "${NGACT}" != "${ACT}" ]] && OKACG="${ACT##*|||}"
    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"
        WARN "${MSG}, RET=${RET}"
    else
        eval "${OKACT}"
    fi
    #### function check RC Block End #####
}<<<'
##############################################

function show_usage {
    cat - <<EOF
Usage: ${g_appname##*/} [-d] [-l <PCAR_URL>]
    -l : URL for pcar
    -d : Debug mode
Example:
    ${g_appname##*/} -l http://xxxxx/xxxx/xxx.pcar
EOF
}

function send_cmd {
    typeset session=$1
    typeset cmd="$2"
    echo "session=$session cmd=$cmd"
    #for _window in $(tmux list-windows -t $session -F "#{window_id},#{window_name}"); do
    for win in $(${TMUX_EXE} list-windows -t $session -F "#{window_id},#{window_name}"); do
        _window=${win%%,*}
        _name=${win##*,}
        [[ "${_name}" == "my" && ${g_force} -eq 0 ]] && echo "ignore my working windows" && continue
        for _pane in $(${TMUX_EXE} list-panes -F '#{pane_id}' -t ${_window}); do
            #echo "window.pane: ${_window}.${_pane} window.name ${_name}"
            CMD="${TMUX_EXE} send-keys -t ${_pane} \"${cmd}\" C-m"
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
        d) g_detach=1; echo "only create session, don't attach";;
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

    if [[ "$(uname)" =~ CYGWIN ]]; then
        cmd="tmux"
    elif [[ "$(uname)" =~ SunOS ]]; then
        export TERM="putty-256color"
        cmd="tmux"
    else
        cmd="tmux -2u"
        # don't use tmux v1.x in /bin/tmux
        if tmux -V | awk '{print $2}' | egrep ^1 >/dev/null; then
            typeset second=$NFS/common/$(uname)/bin/tmux
            [[ -f ${second} ]] && cmd="${second} -2u"
        fi
    fi
    DBG "cmd=$cmd"
    export TMUX_EXE="${cmd}"

    ## send cmd mode
    if [[ -n "${sendcmd}" ]]; then
        send_cmd ${session} "${sendcmd}"
        return 0
    fi

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
            ${cmd} send-keys -t ${session}:${main_win_name}.0 'cd ~; locale; $HOME/smblogin.sh; s; ipconfig;' C-m C-m
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
