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
typeset g_debug_framework=0
typeset g_tmp_list="_tmp.list"
typeset g_tmp_dir="$(pwd)"
typeset g_log="stdout"

typeset g_color_black=`tput   setaf 0`
typeset g_color_red=`tput     setaf 1`
typeset g_color_green=`tput   setaf 2`
typeset g_color_yellow=`tput  setaf 3`
typeset g_color_blue=`tput    setaf 4`
typeset g_color_magenta=`tput setaf 5`
typeset g_color_cyan=`tput    setaf 6`
typeset g_color_white=`tput   setaf 7`
typeset g_color_reset=`tput   sgr0`

##############################################
function DBG {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && [[ "${MYDBG^^}" == "DEBUG" ]] && { typeset srcfile=${BASH_SOURCE[1]##*/}
    typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "$(date +'%Y%m%d_%H:%M:%S') %06d [%03d] [${srcfile} ${funcname}]%s\n" ${BASHPID} ${lineno} "${arg}" >&2; }
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
function LOG {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    typeset srcfile=${BASH_SOURCE[1]##*/}
    printf -v MSG "$(date +'%Y%m%d_%H:%M:%S') %06d [%03d] [${srcfile} ${funcname}]%s\n" ${BASHPID} ${lineno} "${arg}"
    [[ -z ${g_log} || "${g_log}" == "stdout" ]] && printf "%s" "${MSG}" || printf "%s" "${MSG}" >> "${g_log}"
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
function ERR {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    typeset srcfile=${BASH_SOURCE[1]##*/}
    printf "$(date +'%Y%m%d_%H:%M:%S') %06d [%03d] [${srcfile} ${funcname}]%s\n" ${BASHPID} ${lineno} "ERROR: ${arg}" >&2
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
function WARN {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    typeset srcfile=${BASH_SOURCE[1]##*/}
    printf "$(date +'%Y%m%d_%H:%M:%S') %06d [%03d] [${srcfile} ${funcname}]%s\n" ${BASHPID} ${lineno} "WARN: ${arg}" >&2
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
function MSG {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    printf "%s\n" "${arg}"
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
function LOGJSON {
    [[ ${SHELLOPTS} =~ verbose ]] && verbose=1 || verbose=0
    set +vx && typeset file="${1}"; typeset msg="${2}"; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
    typeset srcfile=${BASH_SOURCE[1]##*/}
    printf -v MSG "$(date +'%Y%m%d_%H:%M:%S') %06d [%03d] [${srcfile} ${funcname}]%s\n" ${BASHPID} ${lineno} "${msg}:dump json file ${file}"
    if [[ -z ${g_log} || ${g_log} == "stdout" ]]; then
        echo ${MSG}
        [[ -f "${file}" ]] && cat "${file}" | jq . 2>&1
    else
        echo ${MSG} >> "${g_log}"
        [[ -f "${file}" ]] && cat "${file}" | jq . >> "${g_log}" 2>&1
    fi
    [[ "${verbose}" -eq 1 ]] && set -vx || true
}
##############################################
alias BCS_SH_VERBOSE='set -o | egrep "verbose.*on" >/dev/null 2>&1'
alias BCS_CHK_RC0='{
    #### function check RC Block Begin #####
    RET=$?
    if [[ ${RET} -ne 0 ]]; then
        MSG=$(cat -); ERR "${MSG}, RET=${RET}"; return "${RET}"
    fi
    #### function check RC Block End #####
}<<<'
alias BCS_CHK_ACT_RC0='{
    #### function check RC Block Begin #######################
    ## $1 FORMAT: msg &&& err_actoin ||| ok_action !!! both_action
    ##    msg: print to stdout if RC of last command (that is $!) is not 0
    ##    err_action: shell statement will be run if $? not equal 0
    ##    ok_action : shell statement will be run if $? equal 0
    ##    both_action : shell statement will be run regardless of $!
    ############################################################
    RET=$?;  BCS_SH_VERBOSE && is_verbose=1 || is_verbose=0
    [[ ${g_debug_framework} -ne 1 ]] && set +vx

     INPUTSTR=$(cat -); MSG="${INPUTSTR}"
    MSG="${MSG%%&&&*}"; MSG="${MSG%%|||*}"; MSG="${MSG%%!!!*}";

    NGACT="${INPUTSTR##*&&&}"; [[ "${NGACT}" == "${INPUTSTR}" ]] && NGACT="" \
    || { NGACT="${NGACT%%|||*}"; NGACT="${NGACT%%!!!*}"; }

    OKACT="${INPUTSTR##*|||}"; [[ "${OKACT}" == "${INPUTSTR}" ]] && OKACT="" \
    || { OKACT="${OKACT%%!!!*}"; OKACT="${OKACT%%&&&*}"; }

    ALACT="${INPUTSTR##*!!!}"; [[ "${ALACT}" == "${INPUTSTR}" ]] && ALACT="" \
    || { ALACT="${ALACT%%|||*}"; ALACT="${ALACT%%&&&*}"; }

    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"; eval "${ALACT}"; ERR "${MSG}, RET=${RET}"
        [[ ${is_verbose} -eq 1 ]]  && set -vx || true
        return ${RET}
    else
        eval "${OKACT}"; eval "${ALACT}"
    fi
    [[ ${is_verbose} -eq 1 ]]  && set -vx || true
    #### function check RC Block End #####
}<<<'
alias BCS_RUN_AND_CHK='{
    #### function check RC Block Begin #######################
    ## $1 FORMAT: msg &&& err_actoin ||| ok_action !!! both_action
    ##    msg: print to stdout if RC of last command (that is $!) is not 0
    ##    err_action: shell statement will be run if $? not equal 0
    ##    ok_action : shell statement will be run if $? equal 0
    ##    both_action : shell statement will be run regardless of $!
    ############################################################
    RET=$?;  BCS_SH_VERBOSE && is_verbose=1 || is_verbose=0
    [[ ${g_debug_framework} -ne 1 ]] && set +vx

    INPUTSTR=$(cat -); CMD="${INPUTSTR}"
    CMD="${CMD%%@@@*}"; OTHER="${INPUTSTR##*@@@}"
    [[ "${INPUTSTR}" == "${OTHER}" ]] && OTHER=
    eval "${CMD}"
    BCS_CHK_ACT_RC0 "failed to run (${CMD}),${OTHER}"
    [[ ${is_verbose} -eq 1 ]]  && set -vx || true
    #### function check RC Block End #####
}<<<'
alias BCS_CHK_ACT_EXIT_RC0='{
    #### function check RC Block Begin #######################
    ## $1 FORMAT: msg &&& err_actoin ||| ok_action !!! both_action
    ##    msg: print to stdout if RC of last command (that is $!) is not 0
    ##    err_action: shell statement will be run if $? not equal 0
    ##    ok_action : shell statement will be run if $? equal 0
    ##    both_action : shell statement will be run regardless of $!
    ############################################################
    RET=$?;  BCS_SH_VERBOSE && is_verbose=1 || is_verbose=0
    [[ ${g_debug_framework} -ne 1 ]] && set +vx

     INPUTSTR=$(cat -); MSG="${INPUTSTR}"
    MSG="${MSG%%&&&*}"; MSG="${MSG%%|||*}"; MSG="${MSG%%!!!*}";

    NGACT="${INPUTSTR##*&&&}"; [[ "${NGACT}" == "${INPUTSTR}" ]] && NGACT="" \
    || { NGACT="${NGACT%%|||*}"; NGACT="${NGACT%%!!!*}"; }

    OKACT="${INPUTSTR##*|||}"; [[ "${OKACT}" == "${INPUTSTR}" ]] && OKACT="" \
    || { OKACT="${OKACT%%!!!*}"; OKACT="${OKACT%%&&&*}"; }

    ALACT="${INPUTSTR##*!!!}"; [[ "${ALACT}" == "${INPUTSTR}" ]] && ALACT="" \
    || { ALACT="${ALACT%%|||*}"; ALACT="${ALACT%%&&&*}"; }

    if [[ ${RET} -ne 0 ]]; then
        eval "${NGACT}"; eval "${ALACT}"; ERR "${MSG}, RET=${RET}"
        [[ ${is_verbose} -eq 1 ]]  && set -vx || true
        exit ${RET}
    else
        eval "${OKACT}"; eval "${ALACT}"
    fi
    [[ ${is_verbose} -eq 1 ]]  && set -vx || true
    #### function check RC Block End #####
}<<<'
alias BCS_ASSERT='{
    #### function check RC Block Begin #######################
    ## $1 FORMAT: msg &&& err_actoin ||| ok_action !!! both_action
    ##    msg: print to stdout if RC of last command (that is $!) is not 0
    ##    err_action: shell statement will be run if $? not equal 0
    ##    ok_action : shell statement will be run if $? equal 0
    ##    both_action : shell statement will be run regardless of $!
    ############################################################
    RET=$?;  BCS_SH_VERBOSE && is_verbose=1 || is_verbose=0
    [[ ${g_debug_framework} -ne 1 ]] && set +vx

    INPUTSTR=$(cat -); COND="${INPUTSTR}"
    COND="${COND%%@@@*}"; OTHER="${INPUTSTR##*@@@}"
    [[ "${INPUTSTR}" == "${OTHER}" ]] && OTHER=
    eval "${COND}"
    BCS_CHK_ACT_EXIT_RC0 "ASSERT failed(${COND}),${OTHER}"
    [[ ${is_verbose} -eq 1 ]]  && set -vx || true
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
        DBG "$u is $(type $u)"
    done
}

function my_gen_temp {
    typeset vname=${1?"no var name is specified"}
    typeset appendix=${2:-"tmp"}
    typeset fn="${g_tmp_dir}/tmp.$(id -un).$(date +'%m%d_%H%M%S.%N').$(printf "%05d" $((${RANDOM} % 10000))).${appendix}"
    echo ${fn} >> ${g_tmp_list}
    eval ${vname}="${fn}"
}
function my_clean_temp {
    [[ ! -f ${g_tmp_list} ]] && return 0
    cat ${g_tmp_list} | while read f; do
        ## don't remove log file if it's size is greater than 0
        [[ $f =~ .log$ ]] && [[ -s ${f} ]] && continue
        rm -f $f
    done
    rm -f ${g_tmp_list}
    return 0
}
function my_init_temp {
    > ${g_tmp_list}
    return $?
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
    if [[ ${init_arg} =~ ^- ]]; then
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
    fi

    # check is all mandatory utilities have been ready
    my_check_utility
    BCS_CHK_RC0 "not all mandatory utilities are ready"

    DBG "g_appname=$g_appname"
    DBG "g_apppath=$g_apppath"
    #DBG "\$@=$@"
    DBG "\$@=${init_arg2:+-${init_arg2}} $@"
    ############################################
    my_entry ${init_arg2:+-${init_arg2}} $@
    ############################################

    return $?
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

