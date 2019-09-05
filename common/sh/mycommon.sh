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
typeset g_appname_short

##############################################
function DBG {
    set +vx && [[ "${MYDBG^^}" == "DEBUG" ]] && {
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}" >&2; }
    [[ ${g_verbose} -eq 1 ]] && set -vx || true
}
function LOG {
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
    [[ ${g_verbose} -eq 1 ]] && set -vx || true
}
function ERR {
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "ERROR: ${arg}" >&2
    [[ ${g_verbose} -eq 1 ]] && set -vx || true
}
function WARN {
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "WARN: ${arg}" >&2
    [[ ${g_verbose} -eq 1 ]] && set -vx || true
}
function MSG {
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "%s\n" "${arg}"
    [[ ${g_verbose} -eq 1 ]] && set -vx || true
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

function my_show_usage_entry {
    cat - <<EOF
Usage: ${g_appname_short} [-hdD]
         -d : Debug mode (show DBG log)
         -D : Shell verbose mode (set -vx)
         -h : help
EOF
    type my_show_usage >/dev/null 2>&1 && my_show_usage
}

function my_check_utility {
    for u in ${g_mandatory_utilities[*]}; do
        type $u >/dev/null 2>&1
        BCS_CHK_RC0 "---->$u<---- could not be found in $PATH"
        DBG "$u is $(which $u)"
    done
}

############################################################
function main {
    DBG "BASH_SOURCE: ${BASH_SOURCE[*]}"
    DBG "BASH_ARGV: ${BASH_ARGV[*]}"
    ############################################
    if [[ "$0" =~ ^(/bin/bash|/bin/sh|\-bash)$ && -n "${BASH_SOURCE[-1]}" ]]; then
        DBG "in shell source mode: $0 $@"
    else
        DBG "in normal mode: [$0] $@"
        #export SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
    fi
    export g_apppath="$(cd "$(dirname "${BASH_SOURCE[-1]}")" && pwd)"
    export g_appname=$(basename ${BASH_SOURCE[-1]})
    export g_appname_short=${g_appname##*/}
    export g_verbose=0

    init_arg=$1
    init_arg2=$(echo "${init_arg}" | tr -d '\-dDh')
    shift 1
    if [[ ! -z "$init_arg" ]]; then
        unset OPTIND
        while getopts :dDh ch ${init_arg}; do
            case $ch in
            "d") export MYDBG=DEBUG;;
            "D") export g_verbose=1; set -vx;;
            "h") my_show_usage_entry; return 0;;
            esac
        done
    fi

    # check is all mandatory utilities have been ready
    my_check_utility
    BCS_CHK_RC0 "not all mandatory utilities are ready"

    DBG "g_appname=$g_appname"
    DBG "g_apppath=$g_apppath"
    #DBG "\$@=$@"
    DBG "\$@=${init_arg2:+-${init_arg2}} $@"
    ############################################
    my_entry "${init_arg2:+-"${init_arg2} "}$@"
    ############################################

    return $RET
} 

########################################################
# Following is the sample to use this common shell file
:<<EOFSAMPLE
#!/bin/bash

####### Source my shell script framework ########
source "${SH}/mycommon.sh" 

####### define global variables ##################
typeset -a g_mandatory_utilities=(jq curl awk sed docker) 

###################################################
function my_show_usage {
	cat - <<EOF
Usage: ${g_appname_short} [-u UserName]
         -u : specify docker entry user name
Example:
	${g_appname_short} -u zhaoyong.zzy
EOF
} 
######## write your own logic #####################
function my_entry {
	echo "do your own work"
} 
###########################################
main ${@:+"$@"} 
EOFSAMPLE
########################################################

