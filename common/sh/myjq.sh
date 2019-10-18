#!/bin/bash

###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo

typeset g_appname
typeset jsoncmd=$(cat - <<\EOF
{
  "cmd": {
    "find": {
      "val":    {"func":"json_find_val",  "arg":"<pattern>",  "msg":"find the path whose value is matching the pattern"},
      "key":    {"func":"json_find_key",  "arg":"<pattern>",  "msg":"find the path whose value is matching the pattern"},
      "help":   {"func":"jsonhelp",       "arg":"",  "msg":"help message"}
    },
    "edit": {
      "start":  {"func":"bcs_cpmstart",   "arg":"",  "msg":"start cpm"},
      "init":   {"func":"bcs_cpminit",    "arg":"",  "msg":"initliaze cpm container"},
      "ps":     {"func":"bcs_cpmps",      "arg":"",  "msg":"show process list of cpm container"},
      "help":   {"func":"jsonhelp",       "arg":"",  "msg":"help message"}
    },
    "svctype": {
      "ls":     {"func":"bcs_osslist",    "arg":"<pattern_regexp>",  "msg":"list files on OSS"},
      "cat":    {"func":"bcs_osscat",     "arg":"<file1>",  "msg":"cat one file on OSS"},
      "rm":     {"func":"bcs_ossrm",      "arg":"<file1>",  "msg":"delete one file from OSS"},
      "up":     {"func":"bcs_ossupload",  "arg":"<remote_file> <local_file>",  "msg":"upload one files to OSS"},
      "help":   {"func":"jsonhelp",       "arg":"",  "msg":"help message"}
    },
    "help":   {"func":"jsonhelp",       "arg":"",  "msg":""}
  }
}
EOF
)

function DBG {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	typeset arg="${@}"
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	typeset lineno=${BASH_LINENO[0]}
	printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${arg}"
	printf "%s" "${msg}" >&2
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
	printf "%s" "${msg}" >&2
	return 0
} 

function getpathval {
	typeset p="$1"
	typeset v="$2"
	DBG "p=$p v=$v"
	ret="$(echo "${jsoncmd}" | jq "$p")"
	eval $v="$ret"
}
function pathvalid {
	typeset p="$1"
	DBG "p=$p"
	echo "${jsoncmd}" | jq "${p}" >/dev/null 2>&1
	[[ $? -ne 0 ]] && return 1 || return 0
}
function pathexist {
	typeset p="$1"
	DBG "p=$p"
	[[ "null" == $(echo "${jsoncmd}" | jq "${p}") ]] && return 1 || return 0
}

function getfunc {
	DBG "g_curpath=${g_curpath}"
	for i in cmd $@; do
		g_curpath="${g_curpath}.$i" 
		! pathvalid "${g_curpath}" && break
		DBG "g_curpath=${g_curpath} g_shift=${g_shift}"
		g_curhelppath="${g_curpath}.help" 
		if ! pathexist "${g_curpath}"; then
			DBG "g_curpath=${g_curpath} doesn't exist, break"
			break
		fi
		if pathexist "${g_curhelppath}.func"; then
			g_helppath="${g_curhelppath}"
			getpathval "${g_curhelppath}.func" g_helpfunc
			DBG "g_helpfunc=${g_helpfunc}"
		fi
		if pathexist "${g_curpath}.func"; then
			getpathval "${g_curpath}.func" g_func
			DBG "g_func=${g_func}"
		else
			true
		fi
		((g_shift++))
		continue
	done
}

function jsonhelp {
	typeset p="${1%%.help}"
	echo "Usage for $p"
	echo "${jsoncmd}" | jq -c "$p|keys_unsorted[] as \$k | \$k + \" \" as \$m | \$m + getpath([\$k,\"arg\"]) + \" ----> \" + getpath([\$k,\"msg\"])"
}

function main {
	echo "${jsoncmd}" | jq . > cmd.json
	[[ $? -ne 0 ]] && ERR "json error!!!" && return 1

	g_curpath=""
	g_func=""
	g_helpfunc=""
	g_shift=0

	getfunc ${@}
	DBG "g_func=${g_func}"
	DBG "g_helpfunc=${g_helpfunc}"
	DBG "g_helppath=${g_helppath}"
	DBG "g_shift=${g_shift}"
	[[ "${g_func}" == "${g_helpfunc}" ]] && g_func=""
	[[ -z "${g_func}" ]] && [[ -z "${g_helpfunc}" ]] && ERR "parameter wrong" && return 1
	[[ -z "${g_func}" ]] && [[ -n "${g_helpfunc}" ]] && { ${g_helpfunc} ${g_helppath}; return 0; }
	
	shift $((g_shift - 1))
	DBG "$@"
	${g_func} ${@}
}


#typeset BCS_OSS_PASSWORD="S3v3nteeN!"
#[[ ${BCS_OSS_USER} == "dong.han@oracle.com" ]] && export BCS_OSS_PASSWORD=Welcome1
#[[ ${BCS_OSS_USER} == "jared.li@oracle.com" ]] && export BCS_OSS_PASSWORD=Welcome1
###################################################################
function show_usage {
	echo  "Usage: ${g_appname##*/} command [-l] [-t] [-m msg]"
    echo  "   command : "
    echo  "======================"
	echo  "$(echo ${!aryCmdMap[*]} | sed 's/ /\n/g' | sort)"
    echo  "======================"
}

function showdbg {
	[[ "${MYDBG^^}" != "DEBUG" ]] && return 0
	showmsg_internal "${@}" >&2
} 
function showerr {
	showmsg_internal "ERROR:${@}" >&2
}
function showmsg {
	showmsg_internal "${@}"
}
function showmsg_internal {
    typeset msg
    typeset funcname=${FUNCNAME[2]}
    typeset lineno=${BASH_LINENO[1]}
    printf -v msg "$(date +'%Y%m%d_%H:%M:%S') %08d [%03d] [${funcname}]%s\n" $$ ${lineno} "${1}"
    #printf "%s" "$msg" | tee -a "${CPM_TRACE_FILE}"
    printf "%s" "$msg" 
}

function json_find_key {
	typeset k="$1"
	CMD="$(cat - <<\EOF
jq -c --arg k "$k" 'paths as $p| ($p | length) as $l | select($p[$l-1] | strings, (numbers|tostring) | test($k)) | [ $p, $l, "------>", getpath($p)]'
EOF
)"
	DBG ${CMD}
	eval ${CMD}
}
function json_find_val {
	typeset k="$1"
	set +vx
	CMD="$(cat - <<\EOF
	jq -c --arg k "$k" 'paths as $p|select(getpath($p)| strings,numbers | if type!="string" then tostring else . end|test($k))|[$p,"--->",getpath($p)]' 
EOF
)"
	DBG ${CMD}
	eval ${CMD}
}

#
##################################################
g_appname=${0##*/}
DBG "g_appname=$g_appname"
main ${@}

# some usefule commandline to change something if some condition satisfied
# jq '(.dataSet[] | select(.type.id=="AsynTransactionCheck") | .input.data.timeout) |= 300' 02_parallel_callcontract_balance.json
# jq '((.cells[].outputs | select(.) ) |= []) | (((.cells[].execution_count | select(.))) |= null)'

