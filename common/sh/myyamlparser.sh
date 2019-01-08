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
############################################## 

### this is the sed script used to extract key from yaml file, just for referenct of sed usage
:<<EOF
cat - <<EOF2 > /tmp/yaml.sed 
:begin
/^peer:/,/tls:/ {
    /tls:/! {
        $! {
            N;
            b begin
        }
    }
    s/.*//g
	:b2
	/enabled:/! {s/.*//g; N; b b2;}
	/enabled:/  {s/[^:]*: *//g; p; q 100;}
}
EOF2
EOF
################################################################################ 
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
} 
function usage {
	cat - <<EOF
Usage:  ${g_appname} [-d] <yaml_file> <key_filter>
Example:
	${g_appname}  core.yaml                   #get all key-value
	${g_appname}  core.yaml peer:tls:         #get one child tree
	${g_appname}  core.yaml peer:tls:enabled  #get one specified key's value
EOF
}
function main {
	############################################
	export g_apppath=${0}
	export g_appname=${0##*/}
	[[ ${g_appname} == "bash" ]] && export g_apppath=`pwd`/
	# set debug
	unset OPTIND
	while getopts :s:p:dh ch; do
		DBG "ch=$ch"
		case $ch in
		"d") export MYDBG=DEBUG;;
		"h") usage; return 0;;
		*) echo "wrong parameter $ch"; return 1;;
		esac
	done
	shift $((OPTIND-1))
	DBG "g_appname=$g_appname"
	DBG "g_apppath=$g_apppath"
	############################################

	YAMLFILE=$1
	KEY=$2
	PREFIX="${3:-ZZY_CONF_}"
	[[ -z "${YAMLFILE}" ]] && usage && return 1
	[[ -n "${KEY}" && ( ! "$KEY" =~ :$ ) ]] && KEY="${KEY}="
	DBG "KEY=${KEY}"
	if [[ -n "${KEY}" && ( "$KEY" =~ =$ ) ]]; then
		  parse_yaml ${YAMLFILE} ${PREFIX} | egrep "^${PREFIX}${KEY//:/__}" |  cut -d = -f 2-
	else
		  parse_yaml ${YAMLFILE} ${PREFIX} | egrep "^${PREFIX}${KEY//:/__}"
	fi
}

##################################################################################
main "${@}"
