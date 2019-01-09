#!/bin/bash 

################################
# DEBUG mechianism
#
# Following environmetn variables can be used to debug this shell script
# JESTRACE=DEBUG:     print detailed log
# BP_AWK_DBG=DEBUG:   print debug information for awk script, especially for HTTP port read.
# BP_DBG_FUNC=<regexp for function list>: 
#                     all the matching function's trace will be outputted. example: BP_DBG_FUNC="dm_list|verify_input|load_*"
################################

##PRODUCT_VER###

###############################################
# Set bash global option
###############################################
set -o posix
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo

trap 'onexit' INT

###############################################
# Define gloabl funciton alias
###############################################
alias BP_FUNC_BEGIN='{ 
	#### function header Begin #####
	set +vx
	[[ "${FUNCNAME[0]}" = @(${BP_DBG_FUNC}) ]] && echo "DEBUG: $0 in trace mode" && BPSTACK[$((${#BPSTACK[*]}+1))]="set -vx" || BPSTACK[$((${#BPSTACK[*]}+1))]="set +vx"
	${BPSTACK[${#BPSTACK[*]}]}
	DBGLOG "CALL STACK: $(echo ${FUNCNAME[*]}|sed "s/ / \<\- /g")"
	DBGLOG "BEGIN: $0($#): [$(echo $@)] "
	typeset -i bp_rc=0
	#### function header End #####
 }'
alias BP_FUNC_RETURN='{
	#### function tailer Begin #####
	bp_rc=$(cat -)
	unset BPSTACK[$((${#BPSTACK[*]}))]
	${BPSTACK[${#BPSTACK[*]}]}
	DBGLOG "END (RC=${bp_rc})"
	return "${bp_rc}"
	#### function tailer End #####
}<<<'
alias BP_FUNC_CHK_RC0='{ 
	#### function check RC Block Begin #####
	if [[ $? -ne 0 ]]; then
		BP_FUNC_RETURN 1
	fi
	#### function check RC Block End #####
}'

###############################################
# Define gloabl variables
###############################################
### variable defination begin ####
typeset g_version="${BATCHPLUS_VER:-"internal use only"}" 
declare -a BPSTACK=(true)
typeset g_cpu_count=$([[ `uname` == 'Linux' ]] && nproc 2>/dev/null || { [[ `uname` == "AIX" ]] && lscfg -vp|grep proc 2>/dev/null|wc -l|awk '{print $1}' || echo 2; })

declare -A DOMAIN_NAME=(
[prompt]="Domain name (only a-zA-Z0-9_. is supported, maxinum length is 256):"
[mandatory]="yes"
[type]="input"
[pattern]="^[a-zA-Z0-9_.]{1,255}$"
[list]=""
[default]=""
[value]=""
)
declare -A DOMAIN_PRIVILEGE=(
[prompt]="Will this domain work in security mode? In non-security mode, any OS user can operate this domain. In security mode, only the OS user who has been added to the allowed user list by command <bdadmin -c adduser> can operate this domain."
[mandatory]="no"
[type]="list"
[pattern]=""
[list]="no|yes"
[default]="no"
[value]=""
)
declare -A JOB_LANG=(
[prompt]="What programming language is used in your jobs? If the job is downloaded from mainframe directly, it should be jcl. If the job is migrated from mainframe through ART Workbench, it should be ksh"
[mandatory]="no"
[type]="list"
[pattern]=""
[list]="jcl|ksh"
[default]="jcl"
[value]=""
)
declare -A DOMAIN_ENV_FILE=(
[prompt]="Please specify the full path of environment variables setting file for this domain. if do not specify it, all the necessary environment variables will be set to default value, please reference document for the default value."
[mandatory]="no"
[type]="input"
[pattern]="^/.*"
[list]=""
[default]=""
[value]=""
)
declare -A SVR_NUM_ADMIN=(
[prompt]="How many jobs can be submitted concurrently? The recommend value is the number of CPU core on this machine. The maximum value is 256."
[mandatory]="no"
[type]="input"
[pattern]="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-6])$"
[list]=""
[default]="${g_cpu_count:-2}"
[value]=""
)
declare -A SVR_NUM_INITIATOR=(
[prompt]="How many jobs can be run concurrently? The recommend value is the number of CPU core in this machine. The maximum value is 256."
[mandatory]="no"
[type]="input"
[pattern]="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-6])$"
[list]=""
[default]="${g_cpu_count:-2}"
[value]=""
)
declare -A JOB_REPOSITORY=(
[prompt]="Full paths of Job repository (where your job migrated/downloaded from mainframe are stored), Multiple paths can be set (delimiter is ":")"
[mandatory]="yes"
[type]="input"
[pattern]="^/"
[list]=""
[default]=""
[value]=""
)
declare -A JES_ROOT=(
[prompt]="Full path of the folder to store job log, trace, etc:"
[mandatory]="no"
[type]="input"
[pattern]="^/"
[list]=""
[default]=""
[value]=""
)
declare -A JES_STORAGE=(
[prompt]="What type of storage will be used to store job management data."
[mandatory]="no"
[type]="list"
[pattern]=""
[list]="bdb|oracle"
[default]="bdb"
[value]=""
)
declare -A DB_JES_INSTANCE=(
[prompt]="The DB instance used for batch plus accessing job management data in Oracle DB:"
[mandatory]="yes"
[type]="input"
[encrypt]="yes"
[value]=""
)
declare -A DB_JES_SCHEMA=(
[prompt]="The DB schema used for batch plus accessing job management data in Oracle DB:"
[mandatory]="no"
[type]="input"
[encrypt]="yes"
[value]=""
)
declare -A DB_JES_USER=(
[prompt]="The DB user name used for batch plus accessing job management data in Oracle DB:"
[mandatory]="yes"
[type]="input"
[value]=""
)
declare -A DB_JES_PASSWORD=(
[prompt]="The DB password used for batch plus accessing job management data in Oracle DB:"
[mandatory]="yes"
[hide]="yes"
[type]="input"
[encrypt]="yes"
[value]=""
)
declare -A DB_APP_LOGIN=(
[prompt]="The DB credential (MT_DB_LOGIN) used for application accessing data in Database during runtime(example: scott/tiger@orcl):"
[mandatory]="no"
[type]="input"
[encrypt]="yes"
[value]=""
)
declare -A FTP_APP_PASSWORD=(
[prompt]="The FTP password (MT_FTP_PASS) used for application accessing FTP server during runtime:"
[mandatory]="no"
[hide]="yes"
[type]="input"
[encrypt]="yes"
[value]=""
) 
declare -A WEB_CONSOLE_URL=(
[prompt]="The URL of the web console which will be used to manage this domain. Format: <hostname>:<port>/<path>. Example:\"host1.test.com:10081/web\":"
[mandatory]="no"
[hide]="no"
[type]="input"
[encrypt]="no"
[value]=""
) 
declare -a ary_dm_conf_DUMY=(
DOMAIN_NAME
DOMAIN_PRIVILEGE
)
declare -a ary_dm_conf=(
DOMAIN_NAME
DOMAIN_PRIVILEGE
JOB_LANG
DOMAIN_ENV_FILE
SVR_NUM_ADMIN
SVR_NUM_INITIATOR
JOB_REPOSITORY
JES_ROOT
JES_STORAGE
DB_JES_INSTANCE
DB_JES_USER
DB_JES_PASSWORD
DB_JES_SCHEMA
DB_APP_LOGIN
FTP_APP_PASSWORD
WEB_CONSOLE_URL
)

declare -a ary_dm_db_conf=(
DB_JES_INSTANCE
DB_JES_USER
DB_JES_PASSWORD
DB_JES_SCHEMA
)

declare -A ary_map_cmd_fun=(
[create]="dm_add"
[update]="dm_update"
[delete]="dm_delete"
[list]="dm_list"
[setup]="dm_setup"
[clean]="dm_clean"
[boot]="dm_boot"
[shutdown]="dm_shutdown"
[adduser]="dm_adduser"
[deluser]="dm_deluser"
[listuser]="dm_listuser"
[enroll]="dm_enroll"
[quit]="dm_quit"
[show]="dm_show"
)

typeset g_workspace="" 
typeset g_ifcmd_name="bdadmin" 
typeset g_arg_cmd="" 
typeset g_arg_silent=""
typeset g_arg_option="" 
typeset g_arg_user="" 
typeset g_arg_dm=""
typeset g_arg_profile=""
typeset -i g_arg_showjob=0
typeset -i g_arg_showauth=0
typeset -i g_arg_force=0
typeset -i FDIN=9 
### variable defination end ####

###############################################
# Define gloabl variables
###############################################
### function defination begin ####
function usage {
	typeset str_usg="USAGE:"
	echo "${g_version}"
	echo "${str_usg} ${g_ifcmd_name} -v"
	echo "${str_usg} ${g_ifcmd_name} -h"
	echo "${str_usg} ${g_ifcmd_name} -c create   [profile=<Profile_Path>]"
	echo "${str_usg} ${g_ifcmd_name} -c update   name=<Domain_Name>[,profile=<Profile_Path>]"
	echo "${str_usg} ${g_ifcmd_name} -c delete   name=<Domain_Name>[,force]"
	echo "${str_usg} ${g_ifcmd_name} -c setup    name=<Domain_Name>[,force]"
	echo "${str_usg} ${g_ifcmd_name} -c clean    name=<Domain_Name>[,force]"
	echo "${str_usg} ${g_ifcmd_name} -c adduser  name=<Domain_Name>,user=<User_Name>"
	echo "${str_usg} ${g_ifcmd_name} -c deluser  name=<Domain_Name>,user=<User_Name>"
	echo "${str_usg} ${g_ifcmd_name} -c listuser name=<Domain_Name>"
	echo "${str_usg} ${g_ifcmd_name} -c enroll   name=<Domain_Name>"
	echo "${str_usg} ${g_ifcmd_name} -c quit     name=<Domain_Name>"
	echo "${str_usg} ${g_ifcmd_name} -c list     [name=<Domain_Name>][,showjob][,showauth] "
	echo "${str_usg} ${g_ifcmd_name} -c boot     [name=<Domain_Name>][,force]"
	echo "${str_usg} ${g_ifcmd_name} -c shutdown [name=<Domain_Name>][,force]"
	echo "${str_usg} ${g_ifcmd_name} -c show     [name=<Domain_Name>]"
}

function traceback {
	set +vx
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#FUNCNAME[@]}
  local -i i=0
  local -i j=0

  DBGLOG "Traceback (last called is first):"
  DBGLOG "--------------------------------------------"
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]:-$0}"
    local line="${BASH_LINENO[$j]}"
    DBGLOG "   $((i-1))  ${function}() in ${file}:${line}" 1>&2
  done
  DBGLOG "--------------------------------------------"
}

function DBGLOG {
    set +vx	
	typeset msg
	typeset funcname=${FUNCNAME[1]}
	if [[ "DEBUG" = "${JESTRACE}" ]]; then
		printf -v msg "$(date +'%Y%m%d %H:%M:%S') %08d [DBG] [${funcname}]%s\n" $$ "${1}"
		if [[ -z "${MT_UTIL_TRACE}" ]]; then
			printf "%s" "$msg" >&2
		else
			printf "%s" "$msg" >> "${MT_UTIL_TRACE}"
		fi
	fi
	${BPSTACK[${#BPSTACK[*]}]}
}

function ERRLOG {
    set +vx	
	typeset funcname=${FUNCNAME[1]}
    printf "$(date +'%Y%m%d %H:%M:%S') %08d [ERROR] [${funcname}] %s\n" $$ "$1" >&2
	${BPSTACK[${#BPSTACK[*]}]}
}

function WARNLOG {
	typeset funcname=${FUNCNAME[1]}
    printf "$(date +'%Y%m%d %H:%M:%S') %08d [WARN] [${funcname}] %s\n" $$ "$1" >&2
}

function showwarn {
	typeset lineno=${BASH_LINENO[0]}
	printf "WARN:${lineno:+"[$lineno]"}%s\n" "$1" >&2
}

function showerr {
	typeset lineno=${BASH_LINENO[0]}
	printf "ERROR:${lineno:+"[$lineno]"} %s\n" "$1" >&2
	if [[ "DEBUG" = "${JESTRACE}" ]]; then
		traceback 1
	fi
}

function showmsg {
	typeset lineno=${BASH_LINENO[0]}
	#printf "INFO:${lineno:+"[$lineno]"}%s\n" "$1" >&2
	#printf "[INFO]:%s\n" "$1" >&2
	printf "%s\n" "$1" >&2
}

function create_dm {
	BP_FUNC_BEGIN 
	typeset item=""
	typeset cmd="$1"
	typeset workspace_root=""
	typeset dmroot="${g_workspace}/${DOMAIN_NAME[value]}" 

	if [[ "add" == "${cmd}" && -d "${dmroot}" ]]; then
		showerr "Domain ${DOMAIN_NAME[value]} exist"
		BP_FUNC_RETURN 1
	fi

	mkdir -p "${dmroot}"
	if [[ $? -ne 0 ]]; then
		showerr "Can't create folder: ${dmroot}"
		BP_FUNC_RETURN 1
	fi

	## generate domain profile
	create_dm_profile
	if [[ $? -ne 0 ]]; then
		showerr "Can't create domain profile for: ${dmroot}"
		BP_FUNC_RETURN 1
	fi

	## copy APPDIR template
	cp -r ${JESDIR}/tplt/shm/* "${dmroot}/"
	if [[ $? -ne 0 ]]; then
		showerr "Copy files/folders failed from ${JESDIR}/tplt/shm to ${dmroot}"
		BP_FUNC_RETURN 1
	fi

	export APPDIR="${dmroot}"
	appdir_prepare
	if [[ $? -ne 0 ]]; then
		showerr "Create JES domain failed"
		BP_FUNC_RETURN 1
	fi

	## gen sys profile
	bp_gensysprofile
	if [[ $? -ne 0 ]]; then
		showerr "Create system profile failed"
		BP_FUNC_RETURN 1
	fi

	## Add current user to dm.user, so that artjesadmin can be launched in security mode
	if [[ "${DOMAIN_PRIVILEGE[value]}" == "yes" ]]; then
		launch_and_wait dm_adduser "${DOMAIN_NAME[value]}" "$(id -un)"
		if [[ $? -ne 0 ]]; then
			showerr "Add current user failed"
			BP_FUNC_RETURN 1
		fi
		#echo "$(id -un)" >> "${dmroot}/dm.user"; BP_FUNC_CHK_RC0
	fi

	BP_FUNC_RETURN 0
}

function create_dm_profile {
	BP_FUNC_BEGIN
	typeset name=""
	#typeset value=""
	typeset workspace_root=""
	typeset dmroot="${g_workspace}/${DOMAIN_NAME[value]}"
	typeset dmprofilepath="${dmroot}/dm.profile"

	rm -rf "${dmprofilepath}"
	for name in ${ary_dm_conf[*]}; do
		DBGLOG "=== ${name} ===" 
		eval typeset encrypt=\$\{$name[encrypt]\};
		DBGLOG "encrypt=$encrypt"
		eval typeset value=\$\{$name[value]\};
		DBGLOG "value=$value"
		if [[ "${encrypt}" == "yes" ]]; then
			dm_encrypt "${value}" value
			DBGLOG "new value=$value"
		fi 
		#eval echo \"${name}=\$\{${name}[value]\}\" \>\> \"${dmprofilepath}\"
		echo "${name}=${value}" >> "${dmprofilepath}" 
	done

	BP_FUNC_RETURN 0
}

function create_workspace_root {
	BP_FUNC_BEGIN
	typeset workspace_root
	typeset profilepath="$HOME/.batchplus.conf"
	while true; do
		read -u ${FDIN} -p "Please input the full path of your workspace folder, all the domain will be created in this folder:" g_workspace
		if [[ -z ${g_workspace} || ! "${g_workspace}" =~ ^/ ]]; then
			continue
		else
			echo "WORKSPACE=${g_workspace}" > "${profilepath}"
			if [[ $? -ne 0 ]]; then
				showerr "Can't save profile: ${profilepath}"
				BP_FUNC_RETURN 1
			fi
			break
		fi
	done
	BP_FUNC_RETURN 0
}
function read_workspace_root {
	BP_FUNC_BEGIN
	if [[ -n "${BP_WORKSPACE}" ]]; then
		DBGLOG "read workspace from env BP_WORKSPACE=${BP_WORKSPACE}"
		g_workspace="${BP_WORKSPACE}"
	else
		# read from $HOME/.batchplus.conf
		typeset profilepath="$HOME/.batchplus.conf"
		if [[ ! -f ${profilepath} ]]; then
			## profile doesn't exist
			DBGLOG "profile(${profilepath}) doesn't exist"
			if [[ "${g_arg_silent}" == "yes" ]]; then
				showerr "workspace has not been set in both environment variable (BP_WORKSPACE) and configuration file (${profilepath})"
				BP_FUNC_RETURN 1
			fi
			create_workspace_root
		else
			## profile exist 
			g_workspace="$(egrep "^WORKSPACE=" ${profilepath} 2>/dev/null | sed 's/^WORKSPACE=//g')"
			if [[ -z "${g_workspace}" ]]; then
				if [[ "${g_arg_silent}" == "yes" ]]; then
					showerr "workspace has not been set in both environment variable (BP_WORKSPACE) and configuration file (${profilepath})"
					BP_FUNC_RETURN 1
				fi
				DBGLOG "profile(${profilepath}) exist, but can't read WORKSPACE"
				create_workspace_root
			fi
		fi
	fi

	while true; do
		if [[ ! -d "${g_workspace}" ]]; then
			DBGLOG "create workspace folder: ${g_workspace}"
			mkdir -p "${g_workspace}"
			if [[ $? -ne 0 ]]; then
				showerr "can't create workspace root folder (${g_workspace})"
				if [[ "${g_arg_silent}" == "yes" ]]; then
					BP_FUNC_RETURN 1
				fi
				create_workspace_root
				continue
			fi
		fi
		break
	done 
	BP_FUNC_RETURN 0
}

function dm_encrypt {
	BP_FUNC_BEGIN
	typeset strin=$1
	typeset vname=$2
	typeset crypt_value
	DBGLOG "variable neme: $vname, input: $strin"
	crypt_value="$(artjescrypt -e "${strin}")"
	DBGLOG "crypt_value: ${crypt_value}"
	eval ${vname}=\"${crypt_value}\"
	bp_rc=0
	BP_FUNC_RETURN ${bp_rc}
}

function dm_decrypt {
	BP_FUNC_BEGIN
	typeset strin=$1
	typeset vname=$2
	typeset crypt_value
	DBGLOG "variable neme: $vname, input: $strin"
	crypt_value="$(artjescrypt -d "${strin}")"
	DBGLOG "crypt_value: ${crypt_value}"
	eval ${vname}=\"${crypt_value}\"
	bp_rc=0
	BP_FUNC_RETURN ${bp_rc}
}

function getvalue_by_index {
	BP_FUNC_BEGIN
	typeset item=$1
	typeset index=$2
	eval typeset type=\$\{$item[type]\};
	if [[ "${type}" != "list" ]]; then
		DBGLOG "type of ${item} is ${type}, don't convert"
		BP_FUNC_RETURN 0
	fi
	eval typeset list=\$\{$item[list]\};
	eval ${variable_name}=\$\{list\}

	BP_FUNC_RETURN 0
}

function replace_ubbconfig {
	BP_FUNC_BEGIN
	typeset objfile="${APPDIR}/ubbconfig"
	typeset tmpfile="${APPDIR}/ubbconfig.tmp"
	typeset WEBPORT=8080
	typeset ADM_MAX=${SVR_NUM_ADMIN[value]}
	typeset INI_MAX=${SVR_NUM_INITIATOR[value]}
	typeset DOMAIN_ID="DM${DOMAIN_NAME[value]}"
	typeset WEBURL="${WEB_CONSOLE_URL[value]}"

	typeset IPCKEY
	get_free_ipckey IPCKEY; BP_FUNC_CHK_RC0
	DBGLOG "IPCKEY=${IPCKEY}"

	## don't read port from configuration file of tomcat, its an XML file
	#get_TSAM_http_port WEBPORT; BP_FUNC_CHK_RC0

	export MACHINE="$(uname -n)" 
    export BP_UID=$(id |awk '{print $1}'| tr "(" " "|tr "=" " "|awk '{print $2}')
    export BP_GID=$(id |awk '{print $2}'| tr "(" " "|tr "=" " "|awk '{print $2}')

    sed '
s@<IPCKEY>@'${IPCKEY}'@g
s@<UID>@'${BP_UID}'@g
s@<GID>@'${BP_GID}'@g
s@<TUXDIR>@'${TUXDIR}'@g
s@<APPDIR>@'${APPDIR}'@g
s@<TUXCONFIG>@'${TUXCONFIG}'@g
s@<TLOGDEVICE>@'${TLOGDEVICE}'@g
s@<ULOGPFX>@'${ULOGPFX}'@g
s@<ULOGPFXS>@'${ULOGPFXS}'@g
s@<MACHINE>@'${MACHINE}'@g
s@<WEBPORT>@'${WEBPORT}'@g
s@<WEBURL>@'${WEBURL:-BP_URL_NOVAL}'@g
s@<ADM_MAX>@'${ADM_MAX}'@g
s@<INI_MAX>@'${INI_MAX}'@g
s@<DOMAIN_ID>@'${DOMAIN_ID}'@g
s@<MSTJES>@'${MSTJES}'@g
s@<SLAJES01>@'${SLAJES01}'@g
s@<NADDRPORT>@'${NADDRPORT}'@g
s@<NLSADDRPORT>@'${NLSADDRPORT}'@g
/BP_URL_NOVAL/d
' "${objfile}" > "${tmpfile}"

	## remove LMS if WEBURL is not specified
	#[[ -z "${WEBURL}" ]] && sed -i '/^[ \t]\{0,\}LMS/d' "${tmpfile}"

	cp "${tmpfile}" "${objfile}"; BP_FUNC_CHK_RC0
	rm -f "${tmpfile}"
	DBGLOG "USE_DB: ${JES_STORAGE[value]}"
	DBGLOG "JOBLANG: ${JOB_LANG[value]}"
	DBGLOG "JESROOT: ${JES_ROOT[value]}"
	DBGLOG "JOBREPOSITORY: ${JOB_REPOSITORY[value]}" 

	BP_FUNC_RETURN 0
}

function replace_jesconfig {
	BP_FUNC_BEGIN
	typeset objfile="${APPDIR}/jesconfig"

	DBGLOG "USE_DB: ${JES_STORAGE[value]}"
	DBGLOG "JOBLANG: ${JOB_LANG[value]}"
	DBGLOG "JESROOT: ${JES_ROOT[value]}"
	DBGLOG "JOBREPOSITORY: ${JOB_REPOSITORY[value]}"

	echo "JOBREPOSITORY=${JOB_REPOSITORY[value]}" >> "${objfile}"; BP_FUNC_CHK_RC0
	echo "USE_DB=${JES_STORAGE[value]^^*}" >> "${objfile}"; BP_FUNC_CHK_RC0
	echo "JOBLANG=${JOB_LANG[value]^^*}" >> "${objfile}"; BP_FUNC_CHK_RC0
	echo "JESROOT=${JES_ROOT[value]}" >> "${objfile}"; BP_FUNC_CHK_RC0

	BP_FUNC_RETURN 0
}
#
# get one free ipc key (40000-90000)
# for tuxedo: valid range is > 32768 and < 262143
#
function get_free_ipckey {
	BP_FUNC_BEGIN
    typeset vname=$1 
    typeset value="" 
    typeset freekey=""
    typeset hexvalue=""
    typeset IPCS="ipcs"
    DBGLOG "variable_name=${vname}"
    if [[ -z ${vname} ]]; then
		BP_FUNC_RETURN 2
    fi

    typeset i=0
    while [[ $i -lt 20000 ]]; do
		[[ -z "$SEED_IPCKEY" ]] && SEED_IPCKEY=$(($RANDOM % 19999))
		SEED_IPCKEY=$(($SEED_IPCKEY + $i))
        value=$(awk 'BEGIN{srand('$SEED_IPCKEY');print srand()}')
        DBGLOG "i=$i value=$value"
        value=$(expr $value % 80000)
        value=$(expr $value + 60000)
        hexvalue=$(printf "%08x" $value)
        DBGLOG "i=$i hexvalue=$hexvalue"
        if [[ $(uname) == "SunOS" ]]; then
           ipcs 1>/dev/null
        else
           sudo -n ipcs 1>/dev/null
        fi
        if [[ $? -eq 0 ]]; then
            if [[ $(uname) == "SunOS" ]]; then
                IPCS="ipcs"
            else
                IPCS="sudo -n ipcs"
            fi
        fi
        ${IPCS} |egrep $hexvalue
        if [[ $? -ne 0 ]]; then
            freekey=$value
            break
        else
            DBGLOG "ipckey($value -> 0x$hexvalue) has been used"
        fi
        (( i = i + 1 ))
    done

	if [[ -z "${freekey}" ]]; then
		showerr "Can't find free IPC key"
		BP_FUNC_RETURN 1
	fi

    DBGLOG "freekey=$freekey"
    export SEED_IPCKEY="$freekey"
    eval ${vname}="${freekey}"

	BP_FUNC_RETURN 0
}

function get_TSAM_http_port {
	BP_FUNC_BEGIN
    typeset vname=$1 
    typeset value="" 
	typeset webconf="${JESDIR}//web/apache-tomcat/conf/server.xml"
    DBGLOG "variable_name=${vname}"
    if [[ -z ${vname} ]]; then
		BP_FUNC_RETURN 2
    fi
	### zzy, this port need to read $JESDIR/web/conf/xxxx, this is just a dumy
	value=$(awk -v awkdebug="${BP_AWK_DBG}" '
		function dbg (s) {
			#awkdebug=1
			#printf("%s\n", s) | "cat >&2"; 
			if ("DEBUG" == awkdebug) {
				printf("%s\n", s) > "/dev/stderr";
			} 
		}
		BEGIN {
			iscomment=0; 
			line=""; 
			merging=0; 
			dbg("begin"); 
		}
		/<!--.*-->/ { dbg("Line:" NR " ignored:" $0); next; }
		/^[ \t]*<!--/ { 
			iscomment=1; 
			dbg("Line:" NR ": comment begin " $0); 
			next; 
		}
		/-->/ { 
			iscomment=0; 
			dbg("Line " NR ": comment end " $0);
			next
		}
		/[ \t]*<Connector .*\/>/ { 
			if (1 != iscomment) {
				dbg("Line " NR ": connector3 begin: " $0);
				merging=1
				line=line $0
			}
			next
		}
		/<Connector/ {
			if (0 == iscomment) {
				dbg("Line " NR ": connector begin: " $0);
				merging=1
				line=line $0
				dbg("current line=" line);
			}
			next
		}
		/\/>/ { 
			if (0 == iscomment && 1==merging) {
				dbg("Line " NR ": connector2 end: " $0);
				merging=0
				line=line $0
				gsub(/[\n\r]/, " ", line); 
				dbg("entire line=" line);
				pos=index(line, "protocol=\"HTTP");
				if (pos == 0) { 
					dbg("this is not HTTP");
					next; 
				} else {
					start=match(line,/port=\"[0-9]+\"/);  
					port=substr(line, RSTART+6, RLENGTH-7); 
					dbg("get HTTP port: " port);
					printf(port);
					exit 0;
				}
			}
			next;
		}
		/.*/ {
			if (iscommnet == 0 && merging == 1 ) {
				line=line $0 
				gsub(/[\n\r]/, " ", line); 
				dbg("current line=" line);
			}
			next;
		}' "${webconf}")

	if [[ -z "${value}" ]]; then
		showerr "Failed to get monitor port from file (${webconf})"
		BP_FUNC_RETURN 1
	fi

    eval ${vname}="${value}" 
	BP_FUNC_RETURN 0
}

##
#
# generally IPV4 port range is 32768  61000
#
#
function get_free_port {
    typeset vname=$1
    typeset value=""
    typeset freekey=""
    dbg_echo "[$0] vname=$vname BATCH_USED_PORT=$BATCH_USED_PORT"
    if [[ -z ${vname} ]]; then
        return 1
    fi
    typeset i=0
    while [[ $i -lt 10000 ]]; do
		SEED_PORT_KEY=$(($SEED_PORT_KEY + $i))
        value=$(awk 'BEGIN{srand('$SEED_PORT_KEY');print srand()}')
        dbg_echo "[$0] i=$i value=$value"
        value=$(expr $value + 32768)
        value=$(expr $value % 61000)
        dbg_echo "[$0] i=$i value=$value"
        netstat -an | egrep $value 1>/dev/null
        if [[ $? -ne 0 && ";$BATCH_USED_PORT;" != @(*;$value;*) ]]; then
            freekey=$value
            break
        else
            dbg_echo "[$0] port ($value) has been used"
        fi
        (( i = i + 1 ))
    done
    dbg_echo "[$0] freekey=$freekey"
    export BATCH_USED_PORT="$BATCH_USED_PORT;$freekey"
    export SEED_PORT_KEY="$freekey"
    eval ${vname}=${freekey}
    eval dbg_echo "[$0] $vname=\$$vname"
    return 0;
}

function create_setenv {
	BP_FUNC_BEGIN
	typeset topsetenv="${APPDIR}/setenv.sh"
	typeset setenvfile="${APPDIR}/dm.setenv"
	typeset bpenvfile="${APPDIR}/setenv.bp"
	typeset userenvfile="${DOMAIN_ENV_FILE[value]}"
	typeset mt_root="ejr_cit_ora" 

	get_mt_root mt_root
	##### process dm.setenv
	rm -f "${setenvfile}" 2>/dev/null; BP_FUNC_CHK_RC0 

	echo "#### Begin of auto create ###" >> "${setenvfile}"
	echo "export JESDIR=${JESDIR}" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	echo "export APPDIR=${APPDIR}" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	echo "export TUXDIR=${JESDIR}" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	echo "export JESROOT=${JES_ROOT[value]}" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	echo "export MT_ROOT=${JESDIR}/${mt_root}" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	echo "#### End of auto create ###" >> "${setenvfile}"

	echo "#### Begin of internal ###" >> "${setenvfile}"
	cat "${APPDIR}/setenv.bp" >> "${setenvfile}"; BP_FUNC_CHK_RC0
	rm -f "${APPDIR}/setenv.bp"
	echo "#### End of internal ###" >> "${setenvfile}"

	##### process setenv.sh
	echo ". ${APPDIR}/dm.setenv" > "${topsetenv}"; BP_FUNC_CHK_RC0
	if [[ -n "${userenvfile}" ]]; then
		echo ". ${userenvfile}" >> "${topsetenv}"; BP_FUNC_CHK_RC0 
	fi

	BP_FUNC_RETURN 0
}

function get_mt_root {
	BP_FUNC_BEGIN
	typeset vname=$1 
	typeset userenvfile="${DOMAIN_ENV_FILE[value]}"
	typeset cobol_part=
	typeset db_part=
	if [[ -f "${userenvfile}" ]]; then
			cobol_part=$(export MT_COBOL="COBOL_IT"; source "${userenvfile}"; env | grep "MT_COBOL=" | awk -F[=] '{print $2}' | sed -n 's/^COBOL_MF$/mf/p; s/^COBOL_IT$/cit/p; d')
			db_part=$(export MT_DB="DB_ORACLE"; source "${userenvfile}"; env | grep "MT_DB=" | awk -F[=] '{print $2}' | sed -n 's/^DB_ORACLE$/ora/p; s/^DB_DB2LUW$/db2/p; d')
	fi

    typeset value="ejr_${cobol_part:-"cit"}_${db_part:-"ora"}" 
    eval ${vname}=${value}
	DBGLOG "got: $value"
	BP_FUNC_RETURN 0
}

function appdir_prepare {
	BP_FUNC_BEGIN 

    replace_jesconfig; BP_FUNC_CHK_RC0 
	create_setenv; BP_FUNC_CHK_RC0 

	## source all the environment variables
	source $APPDIR/setenv.sh

    replace_ubbconfig; BP_FUNC_CHK_RC0 

    mkdir -p "${JES_ROOT[value]}"; BP_FUNC_CHK_RC0 
    mkdir -p ${APPDIR}/Logs; BP_FUNC_CHK_RC0 
    mkdir -p ${APPDIR}/data; BP_FUNC_CHK_RC0
    mkdir -p ${APPDIR}/INCL; BP_FUNC_CHK_RC0
    mkdir -p ${APPDIR}/PROC; BP_FUNC_CHK_RC0
    mkdir -p ${APPDIR}/SYSIN; BP_FUNC_CHK_RC0
    mkdir -p ${APPDIR}/acc; BP_FUNC_CHK_RC0

    mkdir -p $MT_TMP; BP_FUNC_CHK_RC0
    mkdir -p $MT_LOG; BP_FUNC_CHK_RC0
    mkdir -p $MT_ACC_FILEPATH; BP_FUNC_CHK_RC0 

	BP_FUNC_RETURN 0
}

function verify_input {
	BP_FUNC_BEGIN
	typeset item=$1
	typeset value=$2
	typeset cmd=$3
	eval typeset mandatory=\$\{$item[mandatory]\}
	eval typeset type=\$\{$item[type]\}
	eval typeset list=\$\{$item[list]\}
	eval typeset pattern=\$\{$item[pattern]\}
	DBGLOG "item($item) value($value)"
	if [[ -z ${item} ]]; then
		showerr "item name is empty"
		BP_FUNC_RETURN 1
	fi

	## public check
	## Check if this field must not be empty
	if [[ -z "${value}" && "${mandatory}" == "yes" ]]; then
		BP_FUNC_RETURN 1
	fi

	## shell injection protect, value can't include ["'`()$^{} ]
	if [[ "${value}" = @(*[\"\'\`\(\) \^\$\{\}]*) ]]; then
		showerr "Invalid value(${value})"
		BP_FUNC_RETURN 1
	fi 

	## set to the array, maybe changed later
	eval ${item}[value]=\"${value}\"
	DBGLOG "set ${item} to <${value}>"

	## set default value to it
	if [[ -z "${value}" ]]; then
		eval value=\"\$\{${item}\[default\]\}\"
		DBGLOG "set default value: $value"
		eval ${item}[value]=\"${value}\"
		#BP_FUNC_RETURN 0
	fi

	## for "list" item, Check if the value exist in the possible value list 
	if eval [[ -n \"${value}\" \&\& \"${type}\" == \"list\" \&\& ! \"${value}\" =~ "^(${list})$" ]]; then
		showerr "Invalid value(${value})"
		BP_FUNC_RETURN 1
	fi

	## for "input" item, Check if the value matching the pattern
	if eval [[ -n \"${value}\" \&\& "${type}" == "input" \&\& ! \"${value}\" =~ "${pattern:-".*"}" ]]; then
		showerr "Invalid value(${value})"
		BP_FUNC_RETURN 1
	fi

	## individual setting
	case "${item}" in
	("DOMAIN_NAME")
		if [[ "${cmd}" =~ "add" ]]; then
			typeset dmroot="${g_workspace}/${DOMAIN_NAME[value]}"
			if [[ -d "${dmroot}" ]]; then
				showerr "Domain (${DOMAIN_NAME[value]}) exist"
				BP_FUNC_RETURN 1
			fi
		fi
		DBGLOG "set all the necessary default value which depends on DOMAIN_NAME"
		JES_ROOT[default]="${g_workspace}/${DOMAIN_NAME[value]}/jesroot"
		;;
	("DOMAIN_ENV_FILE")
		DBGLOG "test domain env file"
		if [[ -n "${value}" ]]; then
			## env file is inputted
			if [[ ! -f "${value}" ]]; then
				## file doesn't exist
				showerr "File (${value}) doesn't exist"
				BP_FUNC_RETURN 1
			fi

			## check syntax, only suppot "export key=value" format
			errlines="$(cat "${value}" | sed '/^[ \t]*$/d' | egrep -v "^[ \t]*#" | egrep -v "^[ \t]*export [^= \t]+=")"
			if [[ -n "${errlines}" ]]; then
				showerr "There are unsupported statements in following lines in file ${value}:"
				echo "${errlines}"
				BP_FUNC_RETURN 1 
			fi

			## check syntax, only suppot "export key=value" format
			errlines="$(bash -n "${value}" 2>&1)"
			if [[ -n "${errlines}" ]]; then
				showerr "There are syntax error in file ${value}:"
				echo "${errlines}"
				BP_FUNC_RETURN 1 
			fi
		fi
		;;
	("JES_STORAGE")
		DBGLOG "set all the necessary value which depends on JES_STORAGE"
		if [[ "${value}" == "bdb" ]]; then
			for db_item in ${ary_dm_db_conf[*]}; do
				eval ${db_item}[mandatory]="no"
			done
			DB_JES_INSTANCE[default]="job.bdb"
			DB_JES_INSTANCE[value]="job.bdb"
		fi
		;;
	("DB_JES_SCHEMA")
		DBGLOG "check DB credential cmd=$cmd"
		if [[ "${JES_STORAGE[value]}" == "oracle" && ! "${cmd}" =~ "load" ]]; then
			Ora_check_db_cred
			if [[ $? -ne 0 ]]; then
				typeset cred="${DB_JES_USER[value]}/${DB_JES_PASSWORD[value]}@${DB_JES_INSTANCE[value]}(${DB_JES_SCHEMA[value]})"
				showerr "Can't connec to DB with credential [${cred}], please check it and environment setting file (${DOMAIN_ENV_FILE[value]:-"no env file"})"
				if [[ "${cmd}" =~ "screen" ]]; then
					typeset answer="n"
					typeset prompt="Will you re-input DB credential? (y/n)"
					read -u ${FDIN} -p "${prompt}" answer
					if [[ "${answer}" == "y" ]]; then 
						## get input from screen
						typeset db_item
						for db_item in ${ary_dm_db_conf[*]}; do
							DBGLOG "=== ${item} ===" 
							getinput "${db_item}" "${cmd}"
						done
					fi
				else
					BP_FUNC_RETURN 1 
				fi
			fi
		fi
		;;
	(*)
		;;
	esac

	BP_FUNC_RETURN 0
}

function Bdb_ExecSQL {
	typeset mt_ResultCode
	dbsql -separator ' ' $1 2>&1 <<-!EOF
		`echo "${3}""\n"`
!EOF
	mt_ResultCode=$?
	#Attache exit code of sqlplus to the Standard Output's last line
 	echo "${mt_ResultCode}" 2>&1
	return ${mt_ResultCode};
}
function Ora_ExecSQL {
	typeset mt_ResultCode
	sqlplus -s $1 <<-!EOF
		set head off
		set linesize 32767
		set heading off
		set feedback off
		set pagesize 0
		set verify off
		set echo off
		set numwidth 20
		set serveroutput on
		whenever oserror exit 125 rollback
		whenever sqlerror exit 126 rollback
		`[[ -n "$2" ]] && echo "Alter session set current_schema=$2;""\n"`
		`echo "${3}""\n"`
		exit;
!EOF
	mt_ResultCode=$?
	#Attache exit code of sqlplus to the Standard Output's last line
 	echo "${mt_ResultCode}" 2>&1
	return ${mt_ResultCode};
}

function Bdb_ExecSQLStr {
	BP_FUNC_BEGIN 
    typeset mt_SQLAccess="$1"
    typeset mt_SQLSchema="$2"
	typeset mt_SQLSTring="$3"
	typeset mt_VariableNameOfResult="$4"
	typeset mt_SQLExecResult=""
	typeset mt_InternalReturnCode
	typeset mt_ErrorMsg=

	# check sqlplus is in PATH
	which "dbsql" >/dev/null 2>&1 
	mt_InternalReturnCode=$?
	if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
		mt_ErrorMsg="cannot find sqlplus in PATH (${PATH})"
		eval "${mt_VariableNameOfResult}"=\"\$\{mt_ErrorMsg\}\"
		#showerr "${mt_ErrorMsg}"
		BP_FUNC_RETURN 1
	fi

	# execute SQL input
	typeset mt_LastLine
	while read line; do
		mt_SQLExecResult="${mt_SQLExecResult}""\n"${line}
		mt_LastLine=$line
	done <<-EOF
		 `Bdb_ExecSQL "${mt_SQLAccess}" "${mt_SQLSchema}" "${mt_SQLSTring}"` 
EOF
	# return code is in the last line of output string
	mt_InternalReturnCode="${mt_LastLine}"
	if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
		mt_ErrorMsg="Bdb_ExecSQL: dbsql execution Error INPUT(\""${mt_SQLSTring}"\") OUTPUT(\""${mt_SQLExecResult}"\") RC(\""${mt_InternalReturnCode}"\")"
		#showerr "${mt_ErrorMsg} rc=${mt_InternalReturnCode}"
		eval "${mt_VariableNameOfResult}"=\"\$\{mt_ErrorMsg\}\"
		BP_FUNC_RETURN 1
	fi
	
	# delete the last line that including exit code
	mt_SQLExecResult="${mt_SQLExecResult%\\n*}"
	eval ${mt_VariableNameOfResult}=\""${mt_SQLExecResult}"\"

	BP_FUNC_RETURN 0
}
function Ora_ExecSQLStr {
	BP_FUNC_BEGIN 
    typeset mt_SQLAccess="$1"
    typeset mt_SQLSchema="$2"
	typeset mt_SQLSTring="$3"
	typeset mt_VariableNameOfResult="$4"
	typeset mt_SQLExecResult=""
	typeset mt_InternalReturnCode
	typeset mt_ErrorMsg=

	# check sqlplus is in PATH
	which "sqlplus" >/dev/null 2>&1 
	mt_InternalReturnCode=$?
	if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
		mt_ErrorMsg="cannot find sqlplus in PATH (${PATH})"
		eval "${mt_VariableNameOfResult}"="\"\${mt_ErrorMsg}\""
		#showerr "${mt_ErrorMsg}"
		BP_FUNC_RETURN 1
	fi

	# execute SQL input
	typeset mt_LastLine
	while read line; do
		mt_SQLExecResult="${mt_SQLExecResult}""\n"${line}
		mt_LastLine=$line
	done <<-EOF
		 `Ora_ExecSQL "${mt_SQLAccess}" "${mt_SQLSchema}" "${mt_SQLSTring}"` 
EOF
	# return code is in the last line of output string
	mt_InternalReturnCode="${mt_LastLine}"
	if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
		mt_ErrorMsg="SQL execution: sqlplus Oracle Error INPUT(\""${mt_SQLSTring}"\") OUTPUT(\""${mt_SQLExecResult}"\") RC(\""${mt_InternalReturnCode}"\")"
		DBGLOG "mt_ErrorMsg=$mt_ErrorMsg"
		#showerr "${mt_ErrorMsg} rc=${mt_InternalReturnCode}"
		eval ${mt_VariableNameOfResult}=\"\$\{mt_ErrorMsg\}\"
		BP_FUNC_RETURN 1
	fi
	
	# delete the last line that including exit code
	mt_SQLExecResult="${mt_SQLExecResult%\\n*}"
	eval ${mt_VariableNameOfResult}=\""${mt_SQLExecResult}"\"

	BP_FUNC_RETURN 0
}

function Ora_check_db_cred {
	BP_FUNC_BEGIN
	typeset conn="$1"
	typeset envfile="${DOMAIN_ENV_FILE[value]}"
	typeset sqloutput
	typeset sql="select sysdate from dual"
	typeset cred="${DB_JES_USER[value]}/${DB_JES_PASSWORD[value]}@${DB_JES_INSTANCE[value]}"

	[[ -f "${envfile}" ]] && . "${envfile}"

	DBGLOG "ORACLE_HOME=$ORACLE_HOME"
	DBGLOG "PATH=$PATH"
	DBGLOG "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
	Ora_ExecSQLStr "${cred}" "${DB_JES_SCHEMA[value]}" "${sql}" sqloutput
	bp_rc=$?

	DBGLOG "sqlplus output: $sqloutput"
	if [[ ${bp_rc} -ne 0 ]]; then
		showerr "${sqloutput}"
		bp_rc=1
	fi

	BP_FUNC_RETURN ${bp_rc}
}
function load_profile {
	BP_FUNC_BEGIN
	typeset dmprofile=$1
	typeset cmd=$2
	typeset item=""

	for item in ${ary_dm_conf[*]}; do
		DBGLOG "=== ${item} ===" 
		typeset name="${item}"
		[[ "${ary_dm_db_conf[*]}" =~ "${name}" && "${JES_STORAGE[value]}" != "oracle" ]] && continue
		## ignore domain name
		[[ "${cmd}" =~ "update" && "${name}" == "DOMAIN_NAME" ]] && continue
		typeset value="$(cat ${dmprofile} | egrep ^${item}= 2>/dev/null| sed 's/^'"${item}"'=//g')"
		DBGLOG "${name}=${value}" 
		verify_input "${name}" "${value}" "${cmd}"
		if [[ $? -ne 0 ]]; then
			showerr "There is error(${name}=${value}) in profile (${dmprofile})"
			bp_rc=1
			break
		fi
		## set to object
		if [[ -n "${value}" ]]; then
			eval ${item}[value]=\"${value}\"
		fi
	done 
	BP_FUNC_RETURN ${bp_rc}
}

function load_dm_profile {
	BP_FUNC_BEGIN
	typeset dmprofile=$1
	typeset item=""

	for item in ${ary_dm_conf[*]}; do
		DBGLOG "=== ${item} ===" 
		typeset name="${item}"
		typeset value="$(cat ${dmprofile} | egrep ^${item}= 2>/dev/null| sed 's/^'"${item}"'=//g')"
		DBGLOG "${name}=${value}"


		## process encrypt 
		eval typeset encrypt=\$\{$name[encrypt]\};
		DBGLOG "encrypt=$encrypt"
		if [[ "${encrypt}" == "yes" ]]; then
			dm_decrypt "${value}" value
			DBGLOG "new value=$value"
		fi 

		verify_input "${name}" "${value}" "load"
		if [[ $? -ne 0 ]]; then
			showerr "There is error(${name}=${value}) in profile (${dmprofile})"
			(( bp_rc++ ))
			#break
			continue
		fi
		## set to object
		if [[ -n "${value}" ]]; then
			eval ${item}[value]=\"${value}\"
		fi
	done 
	BP_FUNC_RETURN ${bp_rc}
}

function getinput {
	BP_FUNC_BEGIN
	typeset name=$1
	typeset cmd=$2
	typeset value=""
	eval typeset prompt=\$\{$name[prompt]\};
	eval typeset list=\$\{$name[list]\};
	eval typeset default=\$\{$name[default]\};
	eval typeset hide=\$\{$name[hide]\};
	eval typeset curval=\$\{$name[value]\};
	if [[ -n "${list}" ]]; then
		prompt="${prompt} (${list})"
	fi
	hide="${hide/no}"

	if [[ "${cmd}" =~ "update" ]]; then
		prompt="${prompt} [current:${curval}]"
	else
		if [[ -n "${default}" ]]; then
			prompt="${prompt} [default:${default}]"
		fi
	fi

	#[[ "${name}" = @(DB_JES_INSTANCE|DB_JES_USER|DB_JES_PASSWORD|DB_JES_SCHEMA) && "${JES_STORAGE[value]}" != "oracle" ]] && BP_FUNC_RETURN 0
	[[ "${ary_dm_db_conf[*]}" =~ "${name}" && "${JES_STORAGE[value]}" != "oracle" ]] && BP_FUNC_RETURN 0

	while true; do
		read -u ${FDIN} -p "${prompt}" ${hide:+"-s"} value
		[[ -n "${hide}" ]] && echo
		echo
		if [[ "${cmd}" =~ "update" && -z "${value}" ]]; then
			DBGLOG "No change, keep current: $curval"
			break;
		fi
		verify_input "${name}" "${value}" "${cmd}"
		if [[ $? -ne 0 ]]; then
			DBGLOG "verify_input failed:" "${name}" "${value}" "${cmd}"
			echo
			continue
		fi
		break
	done
	BP_FUNC_RETURN 0
}
function parse_arg_option {
	BP_FUNC_BEGIN 

	output=$(echo ${g_arg_option} | tr "," "\n" | awk -F "[=]" '
	/^[ \t]*$/ { next;}
	/^[ \t]*name=/ { printf("g_arg_dm=%s;", $2); next;}
	/^[ \t]*domain=/ { printf("g_arg_dm=%s;", $2); next;}
	/^[ \t]*user=/ { printf("g_arg_user=%s;", $2); next;}
	/^[ \t]*profile=/ { printf("g_arg_profile=%s;", $2); next;}
	/^[ \t]*force$/ { printf("g_arg_force=%d;", 1); next;}
	/^[ \t]*showjob$/ { printf("g_arg_showjob=%d;", 1); next;}
	/^[ \t]*showauth$/ { printf("g_arg_showauth=%d;", 1); next;}
	/.*/ { printf("showerr \"Unknown command line option(%s)\"; BP_FUNC_RETURN %d;", $0, 2); exit 1;}
	') 

	DBGLOG "output=[$output]"
	eval "${output}"

	BP_FUNC_RETURN 0
}

function launch_and_wait {
	BP_FUNC_BEGIN 
	typeset func="${@}"
	DBGLOG "func=[${func}]" 

	${func} &
	typeset WAITPID=$!
	DBGLOG "begin to wait child process ${WAITPID}"
	wait ${WAITPID}
	bp_rc=$?  
	DBGLOG "end wait rc=${bp_rc}"
	
	BP_FUNC_RETURN $bp_rc
}

function dm_create_table {
	BP_FUNC_BEGIN 
	case "${JES_STORAGE[value]}" in
	("bdb")
		DBGLOG "Create DB table for bdb"
		sh $JESDIR/tools/CreateTableJobDataBdb.sh "${JESROOT}/job.bdb"
			;;
	("oracle")
		DBGLOG "Create DB table for oracle"
		sh $JESDIR/tools/CreateTableJobDataOra.sh "${DB_JES_USER[value]}/${DB_JES_PASSWORD[value]}@${DB_JES_INSTANCE[value]}" "${DB_JES_SCHEMA[value]}"
		## zzy 
			;;
	(*)
		DBGLOG "unknown DB type: ${JES_STORAGE[value]}"
			;;
	esac 
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_clean_job {
	BP_FUNC_BEGIN 

	for jobdir in $(ls -d ${JESROOT}/???????? 2>/dev/null | egrep "[0-9]{8}$"); do
		DBGLOG "Delete job folder ${jobdir}"
		rm -rf "${jobdir}"
	done
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_clean_table {
	BP_FUNC_BEGIN 
	case "${JES_STORAGE[value]}" in
		("bdb")
			DBGLOG "Clean DB table for bdb"
			typeset bdbfile="${JESROOT}/job.bdb"
			#sh $JESDIR/tools/DropTableJobDataBdb.sh "${bdbfile}"
			rm -f "${bdbfile}"
			rm -rf "${bdbfile}-journal"
			;;
		("oracle")
			DBGLOG "Clean DB table for oracle"
			sh $JESDIR/tools/DropTableJobDataOra.sh "${DB_JES_USER[value]}/${DB_JES_PASSWORD[value]}@${DB_JES_INSTANCE[value]}" "${DB_JES_SCHEMA[value]}"
			;;
		(*)
			showerr "unknown DB type: ${JES_STORAGE[value]}"
			BP_FUNC_RETURN 2
			;;
	esac 

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}

function dm_listuser {
	BP_FUNC_BEGIN 
	typeset dm="${1:-${g_arg_dm}}"
	typeset username="${2:-${g_arg_user}}"
    typeset dmroot=${g_workspace}/${dm}
	DBGLOG "dmroot=[${dmroot}] username[$username]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

    if [[ "yes" != "${dm_privilege}" ]]; then
		showerr "Domain(${dm}) is not working in security mode, can't list user."
		BP_FUNC_RETURN 1
	fi	

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## Add user
	typeset userfile="${dmroot}/dm.user"
	DBGLOG "read user from file ($userfile)"
	cat "${userfile}"; BP_FUNC_RETURN 1
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_deluser {
	BP_FUNC_BEGIN 
	typeset dm="${1:-${g_arg_dm}}"
	typeset username="${2:-${g_arg_user}}"
    typeset dmroot=${g_workspace}/${dm}
	DBGLOG "dmroot=[${dmroot}] username[$username]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

    if [[ "yes" != "${dm_privilege}" ]]; then
		showerr "Domain(${dm}) is not working in security mode, can't delete user."
		BP_FUNC_RETURN 1
	fi	

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## Add user
	typeset userfile="${dmroot}/dm.user"
	DBGLOG "Delete user ($username) from file ($userfile)"
	if `cat "${userfile}" 2>/dev/null | egrep "^${username}$" 2>&1 >/dev/null`; then
		#delete user
		sed -i '/^'"${username}"'$/d' "${userfile}"; BP_FUNC_CHK_RC0 
	else
		showerr "User(${username}) doesn't exist in domain ($dm)"
		BP_FUNC_RETURN 1
	fi

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_enroll {
	BP_FUNC_BEGIN 
	#typeset dm="${1:-${g_arg_dm}}"
    #typeset dmroot=${g_workspace}/${dm}
	typeset dmroot="${1:-${g_arg_dm}}"
	typeset curusr="$(id -un)"
	typeset bpconf="$HOME/.batchplus.conf"
	DBGLOG "dmroot=[${dmroot}] curusr[$curusr]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

    if [[ "yes" != "${dm_privilege}" ]]; then
		showerr "Domain(${dmroot}) is not working in security mode, don't need to enroll it"
		BP_FUNC_RETURN 1
	fi	

    if [[ "${dmroot}" =~ ^"${g_workspace}" ]]; then
		showerr "Domain(${dmroot}) belongs to you, don't need to enroll it"
		BP_FUNC_RETURN 1
	fi	

	#cd ${dmroot}
	#. ./setenv.sh; BP_FUNC_CHK_RC0

	## enroll domain
	typeset userfile="${dmroot}/dm.user"
	DBGLOG "check user ($curusr) exist in file ($userfile)"
	if `cat "${userfile}" 2>/dev/null | egrep "^${curusr}$" 2>&1 >/dev/null`; then
		typeset DOMAIN_AUTH
		eval $(egrep "^DOMAIN_AUTH=" "${bpconf}" 2>/dev/null)
		DBGLOG "Old domain auth list: $DOMAIN_AUTH"
		if [[ ",${DOMAIN_AUTH}," = @(*,${dmroot},*) ]]; then
			showerr "Domain(${dmroot}) had been enrolled, can't enroll again"
			BP_FUNC_RETURN 1
		fi
		## update DOMAIN_AUTH
		sed -i '/^DOMAIN_AUTH/d' "${bpconf}"
		echo "DOMAIN_AUTH=${DOMAIN_AUTH:+${DOMAIN_AUTH},}${dmroot}" >> "${bpconf}" 
	else
		showerr "You has not been authorized to access domain ($dmroot)"
		BP_FUNC_RETURN 1
	fi

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_list_enroll {
	BP_FUNC_BEGIN 
	typeset dm
    #typeset dmroot=${g_workspace}/${dm}
	typeset dmroot="${1:-${g_arg_dm}}"
	typeset curusr="$(id -un)"
	typeset bpconf="$HOME/.batchplus.conf"
	DBGLOG "dmroot=[${dmroot}] curusr[$curusr]" 
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

	## quit domain
	typeset DOMAIN_AUTH
	eval $(egrep "^DOMAIN_AUTH=" "${bpconf}" 2>/dev/null)
	DBGLOG "Old domain auth list: $DOMAIN_AUTH"

	for dm in $(echo ${DOMAIN_AUTH}|tr ',' ' '); do
		{
		DBGLOG "dm=[${dm}]" 
		if [[ ! -d "${dm}" ]]; then
			DBGLOG "dm=[${dm}] is not a folder, ignore" 
			continue
		fi

		typeset dmroot=${dm}
		DBGLOG "dmroot=[${dmroot}]" 
		load_dm_profile "${dmroot}/dm.profile"

		typeset dm_status="Shutdown"
		typeset dm_alive="no"
		typeset dm_sec="${DOMAIN_PRIVILEGE[value]}"
		typeset dm_lang="${JOB_LANG[value]}"
		typeset dm_submit='?'
		typeset dm_success='?'
		typeset dm_fail='?'
		dm_isalive "${dm}" dm_alive
		if [[ $? -ne 0 ]]; then
			dm_status="*Unknown*"
		else if [[ "${dm_alive}" == "yes" ]]; then
			dm_status="Running"
		fi fi 

		## becasue the full path must be very long, make it occupy one line
		printf "%s\n" "${dm}"

		if [[ ${g_arg_showjob} -ne 0 ]]; then
			dm_get_job_info "${dm}" dm_submit dm_success dm_fail
			if [[ $? -ne 0 ]]; then
				DBGLOG "db operation error"	
			fi 
			#printf "${listmask}" "${dm}" "${dm_lang}" "${dm_sec}" "${dm_status}" "${dm_submit}" "${dm_success}" "${dm_fail}"
			printf "${listmask}" " " "${dm_lang}" "${dm_sec}" "${dm_status}" "${dm_submit}" "${dm_success}" "${dm_fail}"
		else
			#printf "${listmask}" "${dm}" "${dm_lang}" "${dm_sec}" "${dm_status}"
			printf "${listmask}" " " "${dm_lang}" "${dm_sec}" "${dm_status}"
		fi
		} 
	done 
	wait

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_quit {
	BP_FUNC_BEGIN 
	#typeset dm="${1:-${g_arg_dm}}"
    #typeset dmroot=${g_workspace}/${dm}
	typeset dmroot="${1:-${g_arg_dm}}"
	typeset curusr="$(id -un)"
	typeset bpconf="$HOME/.batchplus.conf"
	DBGLOG "dmroot=[${dmroot}] curusr[$curusr]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

    if [[ "${dmroot}" =~ ^"${g_workspace}" ]]; then
		showerr "Domain(${dmroot}) belongs to you, don't need to enroll it"
		BP_FUNC_RETURN 1
	fi	

	## quit domain
	typeset DOMAIN_AUTH
	eval $(egrep "^DOMAIN_AUTH=" "${bpconf}" 2>/dev/null)
	DBGLOG "Old domain auth list: $DOMAIN_AUTH"
	if [[ ",${DOMAIN_AUTH}," = @(*,${dmroot},*) ]]; then
		## update DOMAIN_AUTH
		sed -i '/^DOMAIN_AUTH/d' "${bpconf}"

		DOMAIN_AUTH=",${DOMAIN_AUTH},"
		DOMAIN_AUTH="${DOMAIN_AUTH%%,${dmroot},*},${DOMAIN_AUTH##*,${dmroot},}"
		DOMAIN_AUTH=${DOMAIN_AUTH#,}
		DOMAIN_AUTH=${DOMAIN_AUTH%,}
		echo "DOMAIN_AUTH=${DOMAIN_AUTH}" >> "${bpconf}" 
	else
		showerr "Domain(${dmroot}) had not been enrolled, can't quit it"
		BP_FUNC_RETURN 1
	fi

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_adduser {
	BP_FUNC_BEGIN 
	typeset dm="${1:-${g_arg_dm}}"
	typeset username="${2:-${g_arg_user}}"
    typeset dmroot=${g_workspace}/${dm}
	DBGLOG "dmroot=[${dmroot}] username[$username]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset dm_privilege="${DOMAIN_PRIVILEGE[value]}"

    if [[ "yes" != "${dm_privilege}" ]]; then
		showerr "Domain(${dm}) is not working in security mode, can't add user."
		BP_FUNC_RETURN 1
	fi	

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## Add user
	typeset userfile="${dmroot}/dm.user"
	DBGLOG "Add user ($username) to file ($userfile)"
	if `cat "${userfile}" 2>/dev/null | egrep "^${username}$" 2>&1 >/dev/null`; then
		typeset dumy
		showwarn "user ($username) had been added to domain ($dm), ignore"
	else
		echo "${username}" >> "${userfile}"; BP_FUNC_CHK_RC0
	fi

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}

function dm_boot {
	BP_FUNC_BEGIN 
	typeset dmlist=
	typeset dm=

	if [[ -z "${g_arg_dm}" ]]; then
		dmlist=$(ls "${g_workspace}")
	else
		dmlist="${g_arg_dm}"
	fi 

	DBGLOG "dmlist=[${dmlist}]" 
	for dm in ${dmlist}; do 
		if [[ ! -d "${g_workspace}/${dm}" ]]; then
			DBGLOG "dm=[${dm}] is not a folder, ignore" 
			continue
		fi
		showmsg "Boot domain (${dm})"
		launch_and_wait dm_boot_internal "${dm}"
	done
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_list {
	BP_FUNC_BEGIN 
	
	launch_and_wait dm_list_internal
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_shutdown {
	BP_FUNC_BEGIN 

	typeset dmlist=
	typeset dm=
	if [[ -z "${g_arg_dm}" ]]; then
		dmlist=$(ls "${g_workspace}")
	else
		dmlist="${g_arg_dm}"
	fi 
	DBGLOG "dmlist=[${dmlist}]" 

	if [[ "${g_arg_force}" -ne 1 ]]; then
		typeset answer="n"
		#typeset prompt="Do you really want to shutdown domain ($(echo ${dmlist} | tr '\n' ' ' | sed 's/ $//g'))? (y/n)"
		typeset prompt="Do you really want to shutdown all domains? (y/n)"
		read -u ${FDIN} -p "${prompt}" answer
		if [[ "${answer}" != "y" ]]; then 
			BP_FUNC_RETURN 1
		fi
	fi 

	for dm in ${dmlist}; do 
		if [[ ! -d "${g_workspace}/${dm}" ]]; then
			DBGLOG "dm=[${dm}] is not a folder, ignore" 
			continue
		fi
		showmsg "shutdown domain (${dm})"
		launch_and_wait dm_shutdown_internal ${dm}
	done

	bp_rc=$?  
	if [[ $bp_rc -ne 0 ]]; then
		showerr "Shutdown Domain($dm) failed" 
		BP_FUNC_RETURN $bp_rc
	fi
     	
	BP_FUNC_RETURN $bp_rc
}
function dm_delete {
	BP_FUNC_BEGIN 
	
	if [[ "${g_arg_force}" -ne 1 ]]; then
		typeset answer="n"
		typeset prompt="Do you really want to delete domain (${g_arg_dm})? (y/n)"
		read -u ${FDIN} -p "${prompt}" answer
		if [[ "${answer}" != "y" ]]; then 
			BP_FUNC_RETURN 1
		fi
	fi 

	launch_and_wait dm_clean_internal
	launch_and_wait dm_delete_internal
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_show {
	BP_FUNC_BEGIN 

    typeset dmroot=${g_workspace}/${g_arg_dm}
	[[ ${g_arg_dm} =~ / ]] && dmroot="${g_arg_dm}"
	DBGLOG "dmroot=[${dmroot}]" 
	#load_dm_profile "${dmroot}/dm.profile"

	cat "${dmroot}/dm.profile"

	## clean TLOG
    
	bp_rc=0

	BP_FUNC_RETURN $bp_rc
}
function dm_setup {
	BP_FUNC_BEGIN 

	## check if domain has been setup
	if [[ -f "${g_workspace}/${g_arg_dm}/tuxconfig" ]]; then
		if [[ "${g_arg_force}" -ne 1 ]]; then
			typeset answer="n"
			typeset prompt="Domain(${g_arg_dm}) has been set up, do you want to clean it and setup again?(y/n)"
			read -u ${FDIN} -p "${prompt}" answer
			DBGLOG "answer=${answer}"
			if [[ "${answer}" != "y" ]]; then 
				BP_FUNC_RETURN 1
			fi
		fi 

		## clean this domain, don't call dm_clean directly, otherwise the confirm prompt will be shown again
		launch_and_wait dm_clean_internal
    fi	

	launch_and_wait dm_setup_internal 
	bp_rc=$?  
	if [[ $bp_rc -ne 0 ]]; then
		showerr "Setup Domain failed" 
		BP_FUNC_RETURN $bp_rc
	fi

	BP_FUNC_RETURN $bp_rc
}

function dm_clean {
	BP_FUNC_BEGIN 

	if [[ "${g_arg_force}" -ne 1 ]]; then
		typeset answer="n"
		typeset prompt="Do you really want to clean domain (${g_arg_dm})? (y/n)"
		read -u ${FDIN} -p "${prompt}" answer
		if [[ "${answer}" != "y" ]]; then 
			BP_FUNC_RETURN 1
		fi
	fi 
	
	launch_and_wait dm_clean_internal
	bp_rc=$?  
	if [[ $bp_rc -ne 0 ]]; then
		showerr "Clean Domain(${g_arg_dm}) failed" 
		BP_FUNC_RETURN $bp_rc
	fi
     	
	BP_FUNC_RETURN $bp_rc
}
function dm_isalive {
	BP_FUNC_BEGIN 
	typeset dm_name=$1
	typeset vname=$2
	typeset value
    typeset ubb
	if [[ "${dm_name}" =~ ^/ ]]; then
    	ubb="${dm_name}/ubbconfig"
	else
    	ubb="${g_workspace}/${dm_name}/ubbconfig"
	fi
	typeset ipckey="$(cat "${ubb}" 2>/dev/null| grep IPCKEY | awk '{print $2}')"

	if [[ -z "${ipckey}" ]]; then
		value="no"
		eval ${vname}=\"${value}\" 
		BP_FUNC_RETURN 1
	fi

	typeset hexvalue=$(printf "%08x" "${ipckey}")
	DBGLOG "ipckey=$ipckey hexvalue=$hexvalue"
	if [[ $(uname) == "SunOS" ]]; then
	   ipcs 1>/dev/null
	else
	   sudo -n ipcs 1>/dev/null
	fi
	if [[ $? -eq 0 ]]; then
		if [[ $(uname) == "SunOS" ]]; then
			IPCS="ipcs"
		else
			IPCS="sudo -n ipcs"
		fi
	fi
	${IPCS} |egrep $hexvalue >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		DBGLOG "ipckey($ipckey -> 0x$hexvalue) has NOT been used"
		value="no"
	else
		DBGLOG "ipckey($ipckey -> 0x$hexvalue) has been used"
		value="yes"
	fi
	eval ${vname}=\"${value}\" 
     	
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}

function dm_delete_internal {
	BP_FUNC_BEGIN 
    typeset dmroot=${g_workspace}/${g_arg_dm}
	DBGLOG "dmroot=[${dmroot}]" 

	## delete top folder
	rm -rf "${dmroot}"; BP_FUNC_CHK_RC0 
    
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}

function dm_clean_internal {
	BP_FUNC_BEGIN 
    typeset dmroot=${g_workspace}/${g_arg_dm}
	DBGLOG "dmroot=[${dmroot}]" 
	load_dm_profile "${dmroot}/dm.profile"

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## clean TLOG
	showmsg "Cleaning Log files"
	rm -f "${dmroot}/TLOG"; BP_FUNC_CHK_RC0
	rm -f "${dmroot}/ULOG*"; BP_FUNC_CHK_RC0
	rm -f "${MT_LOG}/*"; BP_FUNC_CHK_RC0

	showmsg "Cleaning temporary files"
	rm -f "${MT_TMP}/*"; BP_FUNC_CHK_RC0

	## clean DB table for job management
	showmsg "Cleaning Database"
	dm_clean_table; BP_FUNC_CHK_RC0

	## clean DB table for job management
	showmsg "Cleaning Jobs"
	dm_clean_job; BP_FUNC_CHK_RC0

	## clean domain working files
	showmsg "Cleaning domain working files"
	rm -f "${dmroot}/tuxconfig"; BP_FUNC_CHK_RC0 
	rm -f "${MT_ACC_FILEPATH}/*"; BP_FUNC_CHK_RC0 
    
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_boot_internal {
	BP_FUNC_BEGIN 
	typeset dm=$1
    typeset dmroot=${g_workspace}/${dm}
	DBGLOG "dmroot=[${dmroot}]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset jes_storage="${JES_STORAGE[value]}"

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## load UBBCONFIG
	tmboot -y;  BP_FUNC_CHK_RC0 
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}

function dm_list_internal {
	BP_FUNC_BEGIN 
	typeset listmask
	typeset linelen
    typeset dmlist
	if [[ -z "${g_arg_dm}" ]]; then
		dmlist=$(ls "${g_workspace}")
	else
		dmlist="${g_arg_dm}"
	fi 

	DBGLOG "dmlist=[${dmlist}]" 
	typeset listmask_base="%-32s %-4s %-4s %-10s"
	if [[ ${g_arg_showjob} -ne 0 ]]; then
		listmask="${listmask_base} %8s %8s %8s\n"
		linelen=81
		printf "${listmask}" "Domain" "lang" "sec" "Status" "submit" "success" "fail"
	else
		listmask="${listmask_base}\n"
		linelen=52
		printf "${listmask}" "Domain" "lang" "sec" "Status"
	fi
	printf "%s\n" "$(eval printf '=%.0s' {1..${linelen}})"
	if [[ ${g_arg_showauth} -eq 0 ]]; then

		for dm in ${dmlist}; do
			{
			DBGLOG "dm=[${dm}]" 
			if [[ ! -d "${g_workspace}/${dm}" ]]; then
				DBGLOG "dm=[${dm}] is not a folder, ignore" 
				continue
			fi

			typeset dmroot=${g_workspace}/${dm}
			DBGLOG "dmroot=[${dmroot}]" 
			load_dm_profile "${dmroot}/dm.profile"

			typeset dm_status="Shutdown"
			typeset dm_alive="no"
			typeset dm_sec="${DOMAIN_PRIVILEGE[value]}"
			typeset dm_lang="${JOB_LANG[value]}"
			typeset dm_submit='?'
			typeset dm_success='?'
			typeset dm_fail='?'
			dm_isalive "${dm}" dm_alive
			if [[ $? -ne 0 ]]; then
				dm_status="*Unknown*"
			else if [[ "${dm_alive}" == "yes" ]]; then
				dm_status="Running"
			fi fi 

			if [[ ${g_arg_showjob} -ne 0 ]]; then
				dm_get_job_info "${dm}" dm_submit dm_success dm_fail
				if [[ $? -ne 0 ]]; then
					DBGLOG "db operation error"	
				fi 
				printf "${listmask}" "${dm}" "${dm_lang}" "${dm_sec}" "${dm_status}" "${dm_submit}" "${dm_success}" "${dm_fail}"
			else
				printf "${listmask}" "${dm}" "${dm_lang}" "${dm_sec}" "${dm_status}"
			fi
			} &
		done 
		wait
		printf "%s\n" "$(eval printf '=%.0s' {1..${linelen}})"
	else 
		## enrolled domain
		#printf "%s\n" "<<Enrolled domain>>"
		dm_list_enroll 
		printf "%s\n" "$(eval printf '=%.0s' {1..${linelen}})"
	fi
     	
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_get_job_info {
	BP_FUNC_BEGIN 
	typeset dm=$1
	typeset dmroot
	typeset var_submit=$2
	typeset var_success=$3
	typeset var_fail=$4

	if [[ "${dm}" =~ ^/ ]]; then
		dmroot=${dm}
	else
		dmroot=${g_workspace}/${dm}
	fi

	typeset envfile="${DOMAIN_ENV_FILE[value]}"
	typeset jes_storage="${JES_STORAGE[value]}"
	[[ -f "${envfile}" ]] && . "${envfile}"

	typeset mt_SQLStrInput
	typeset mt_SQLStrOutput
	case "${jes_storage}" in
	("bdb")
		DBGLOG "Execute sql for bdb"
		typeset bdbfile="${JESROOT}/job.bdb"
		#sh $JESDIR/tools/DropTableJobDataBdb.sh "${bdbfile}"
		typeset cred="${JES_ROOT[value]}/${DB_JES_INSTANCE[value]}"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM;\n"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM WHERE STATUS='DONE';\n"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM WHERE STATUS='FAIL';\n"
		Bdb_ExecSQLStr "${cred}" "${DB_JES_SCHEMA[value]}" "${mt_SQLStrInput}" mt_SQLStrOutput 
		typeset mt_InternalReturnCode=$?
		if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
			#showerr "Execute SQL statement failed"
			DBGLOG "Execute SQL statement failed: input($mt_SQLStrInput) output($mt_SQLStrOutput)"
			BP_FUNC_RETURN 3
		fi
		;;
	("oracle")
		DBGLOG "ORACLE_HOME=$ORACLE_HOME"
		DBGLOG "PATH=$PATH"
		DBGLOG "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
		typeset cred="${DB_JES_USER[value]}/${DB_JES_PASSWORD[value]}@${DB_JES_INSTANCE[value]}"
		mt_SQLStrInput="set colsep \" \";\n"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM;\n"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM WHERE STATUS='DONE';\n"
		mt_SQLStrInput="${mt_SQLStrInput}SELECT COUNT(*) FROM JES2_JOB_PARAM WHERE STATUS='FAIL';\n"
		Ora_ExecSQLStr "${cred}" "${DB_JES_SCHEMA[value]}" "${mt_SQLStrInput}" mt_SQLStrOutput 
		typeset mt_InternalReturnCode=$?
		if [[ ${mt_InternalReturnCode} -ne 0 ]]; then
			#showerr "Execute SQL statement failed"
			DBGLOG "Execute SQL statement failed: input($mt_SQLStrInput) output($mt_SQLStrOutput)"
			BP_FUNC_RETURN 3
		fi
		;;
	(*)
		showerr "unknown DB type: ${JES_STORAGE[value]}"
		BP_FUNC_RETURN 2
		;;
	esac 

	DBGLOG "mt_SQLStrOutput=${mt_SQLStrOutput}"
	typeset line
	typeset -i i=0
	while read line; do
        if [[ -z "${line}" ]]; then
            continue
        fi
        (( i=i+1 ))
		case $i in
		(1) eval "${var_submit}"=$line;;
		(2) eval "${var_success}"=$line;;
		(3) eval "${var_fail}"=$line;;
		esac 
	done <<-EOF
	`echo ${mt_SQLStrOutput}`
EOF
	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}
function dm_shutdown_internal {
	BP_FUNC_BEGIN 
	typeset dm=$1
    typeset dmroot=${g_workspace}/${dm}
	DBGLOG "dmroot=[${dmroot}]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset jes_storage="${JES_STORAGE[value]}"

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## load UBBCONFIG
	tmshutdown -yc;  BP_FUNC_CHK_RC0 
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}

function dm_setup_internal {
	BP_FUNC_BEGIN 
    typeset dmroot=${g_workspace}/${g_arg_dm}
	DBGLOG "dmroot=[${dmroot}]" 
	load_dm_profile "${dmroot}/dm.profile"
	typeset jes_storage="${JES_STORAGE[value]}"

	cd ${dmroot}
	. ./setenv.sh; BP_FUNC_CHK_RC0

	## Create TLOG
	./crlog; BP_FUNC_CHK_RC0

	## Create acclock
    >$MT_ACC_FILEPATH/AccWait; BP_FUNC_CHK_RC0
    >$MT_ACC_FILEPATH/AccLock; BP_FUNC_CHK_RC0

	## Create DB table for job management
	dm_create_table; BP_FUNC_CHK_RC0

	## load UBBCONFIG
	tmloadcf -y ubbconfig; BP_FUNC_CHK_RC0
	
	## add read permission for all users
	chmod a+r "${dmroot}/tuxconfig" 
     	
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}
function dm_update {
	BP_FUNC_BEGIN 
	DBGLOG "g_arg_profile=[${g_arg_profile}]" 

    typeset dmroot=${g_workspace}/${g_arg_dm}
	DBGLOG "dmroot=[${dmroot}]" 
	load_dm_profile "${dmroot}/dm.profile"

	if [[ -z "${g_arg_profile}" ]]; then
		## get input from screen
		for item in ${ary_dm_conf[*]}; do
			if [[ "${item}" == "DOMAIN_NAME" ]]; then
				continue
			fi
			DBGLOG "=== ${item} ===" 
			getinput "${item}" "update_profile"
		done
	else
		## get input from pre-defined profile
		if [[ ! -f "${g_arg_profile}" ]]; then
			showerr "Pre-defined domain profile (${g_arg_profile}) doesn't exist or can NOT be accessed"
			BP_FUNC_RETURN 1
		fi
		load_profile "${g_arg_profile}" "update_profile"
		BP_FUNC_CHK_RC0
	fi

	## update JES domain
	create_dm "update"
	bp_rc=$?
	BP_FUNC_RETURN $bp_rc
}

function dm_add {
	BP_FUNC_BEGIN 
	DBGLOG "g_arg_profile=[${g_arg_profile}]" 
	if [[ -z "${g_arg_profile}" ]]; then
		## get input from screen
		for item in ${ary_dm_conf[*]}; do
			DBGLOG "=== ${item} ===" 
			getinput "${item}" "add_screen"
		done
	else
		## get input from pre-defined profile
		if [[ ! -f "${g_arg_profile}" ]]; then
			showerr "Pre-defined domain profile (${g_arg_profile}) doesn't exist or can NOT be accessed"
			BP_FUNC_RETURN 1
		fi
		load_profile "${g_arg_profile}" "add_profile"
		BP_FUNC_CHK_RC0
	fi

	## create JES domain
	create_dm "add"
	bp_rc=$?  
	BP_FUNC_RETURN $bp_rc
}

function bp_gensysprofile {
	BP_FUNC_BEGIN 
	typeset sysprofile="${JES_ROOT[value]}/.jessysprofile"
	declare -a ary_dm_sysprofile=(
	DB_JES_USER
	DB_JES_PASSWORD
	DB_JES_INSTANCE
	DB_JES_SCHEMA
	DB_APP_LOGIN
	FTP_APP_PASSWORD
	) 

	rm -f  "${sysprofile}"

	for name in ${ary_dm_sysprofile[*]}; do
		DBGLOG "=== ${name} ===" 
		eval typeset encrypt=\$\{$name[encrypt]\};
		DBGLOG "encrypt=$encrypt"
		eval typeset value=\"\$\{$name[value]\}\";
		DBGLOG "value=$value"
		if [[ "${encrypt}" == "yes" ]]; then
			dm_encrypt "${value}" value
			DBGLOG "new value=$value"
		fi 
		echo "${value}" >>  "${sysprofile}"; BP_FUNC_CHK_RC0
	done

	## output of genjesprofile and gensysprofile
	false && cat - <<-EOF
	zhaozhan:~/sanity/cron/cvs_batch_sanity/cases/zip/case_zip/tmp/ejr_cit_ora>gensysprofile -d $PWD
	gensysprofile will create a profile "/home/zhaozhan/sanity/cron/cvs_batch_sanity/cases/zip/case_zip/tmp/ejr_cit_ora/.jessysprofile"
	User name (0~30 characters):a
	User Password (0~31 characters):
	Confirm User Password (0~31 characters):
	Database instance name:a
	DB Schema(Optional):a
	/home/zhaozhan/sanity/cron/cvs_batch_sanity/cases/zip/case_zip/tmp/ejr_cit_ora/.jessysprofile is created successfully

	zhaozhan@bej301738:/nfs/users/zhaozhan/dev/batchplus/src>cat /home/zhaozhan/sanity/cron/cvs_batch_sanity/cases/zip/case_zip/tmp/ejr_cit_ora/.jessysprofile
	a
	FTEUt10dXYSWnpLEnmGH1XhywmiQ8DfonLZAFo8D7jQ=
	FTEUt10dXYSWnpLEnmGH1XhywmiQ8DfonLZAFo8D7jQ=
	FTEUt10dXYSWnpLEnmGH1XhywmiQ8DfonLZAFo8D7jQ=


	zhaozhan:~/sanity/cron/cvs_batch_sanity/cases/zip/case_zip/tmp/ejr_cit_ora>genjesprofile
	genjesprofile will create a profile "/home/zhaozhan/.tuxAppProfile"
	Application Password (0~31 characters):
	Confirm Application Password (0~31 characters):
	User name (0~30 characters):a
	User Password (0~31 characters):
	Confirm User Password (0~31 characters):
	Database connection string for MT_DB_LOGIN:a/a@a
	Database connection string for MT_GDG_DB_ACCESS:a/a@1
	Database connection string for MT_DB_LOGIN2:a/a@1
	Database connection string for MT_CATALOG_DB_LOGIN:a/a@1
	Ftp password for MT_FTP_PASS:a/a@2
	/home/zhaozhan/.tuxAppProfile is created successfully

	zhaozhan@bej301738:/nfs/users/zhaozhan/dev/batchplus/src>cat /home/zhaozhan/.tuxAppProfile
	FTEUt10dXYSWnpLEnmGH1XhywmiQ8DfonLZAFo8D7jQ=
	a
	FTEUt10dXYSWnpLEnmGH1XhywmiQ8DfonLZAFo8D7jQ=
	AjimEL/YeyyVPjOrLY2Swr7bkLILrgxA9SoHqSLFewc=
	dsXJAMccRmlxOVLKdBMe+fEAOXOH6Z0mT96EZjamMK4=
	dsXJAMccRmlxOVLKdBMe+fEAOXOH6Z0mT96EZjamMK4=
	dsXJAMccRmlxOVLKdBMe+fEAOXOH6Z0mT96EZjamMK4=
	yu8n9mEwVKNyJAGo+BGz/LSmKmwioLSkyPmsOMMOdeM=

EOF

	bp_rc=0
	BP_FUNC_RETURN $bp_rc
}

function onexit {
	DBGLOG "trap EXIT"
	exit 1
}

function bpmain { 
	BP_FUNC_BEGIN
	## set global variables 
	typeset zzyout
	#Ora_ExecSQLStr "scott/tiger@orcl" "scott" "select sysdate from dual;" zzyout
	#Ora_ExecSQLStr "scott/tiger@orcl" "" "select sysdate from dual;" zzyout
	#Ora_ExecSQLStr "scott/tiger@orcl" "" "" zzyout
	#echo "ret=$? zzyout=$zzyout" 
	#exit

	for((i=0; i<=$#; i++)); do
		eval val=\$$i
		DBGLOG "ARGV[$i]=$val"
	done

	## analyze arguments
	while getopts ":c:hSv" ch; do
		case "${ch}" in
		("S") 
			g_arg_silent="yes"
			DBGLOG "g_arg_silent=${g_arg_silent}"
			;;
		("c") 
			g_arg_cmd="${OPTARG}"
			DBGLOG "g_arg_cmd=${g_arg_cmd}"
			;;
		("h") 
			usage
			BP_FUNC_RETURN 0
			;;
		("v") 
			echo "${g_version}"
			BP_FUNC_RETURN 0
			;;
		(?)
			usage
			BP_FUNC_RETURN 3
			;;
		esac
	done
	
	if [[ -z "${g_arg_cmd}" ]]; then
		usage
		BP_FUNC_RETURN 0
	fi

	## check cmd 
	if [[ ! " ${!ary_map_cmd_fun[*]} " =~ " ${g_arg_cmd} " ]]; then
		showerr "Invalid command (${g_arg_cmd}), command must be one of [${!ary_map_cmd_fun[*]}]"
		BP_FUNC_RETURN 1
	fi

	shift $(( OPTIND - 1 ))
	g_arg_option="${@}"

	## parse the entire options
	parse_arg_option
	BP_FUNC_CHK_RC0

	DBGLOG "g_arg_option=${g_arg_option}"
	DBGLOG "g_arg_dm=${g_arg_dm}"
	DBGLOG "g_arg_user=${g_arg_user}"
	DBGLOG "g_arg_force=${g_arg_force}"

	## bdadmin will open FD=9
	typeset fdfilepath=/proc/$$/fd/${FDIN}
	DBGLOG "fdfilepath=${fdfilepath}"
	if [[ ! -L ${fdfilepath} ]]; then
		DBGLOG "Open FD ${FDIN}" 
		eval exec ${FDIN}\<\&0
	fi

	###### Get/Save workspace #######
	read_workspace_root
	if [[ $? -ne 0 ]]; then
		## Can't get workspace root
		BP_FUNC_RETURN 1
	fi 
	DBGLOG "workspace root: $g_workspace"

	#### TEST ####
	# check basic parameter
	if [[ "${g_arg_cmd}" == @(update|delete|setup|clean|adduser|deluser|listuser) ]]; then
		if [[ -z "${g_arg_dm}" ]]; then
			showerr "Domain name is not specified"
			BP_FUNC_RETURN 1
		fi
	fi 

	# check domain existance
	if [[ -n "${g_arg_dm}" && ! -d "${g_workspace}/${g_arg_dm}" && "${g_arg_cmd}" != "create" && ! ${g_arg_dm} =~ ^/ ]]; then
		showerr "Domain (${g_arg_dm}) doesn't exist"
		BP_FUNC_RETURN 1
	fi
	## the domain with full path must exist
	if [[ -n "${g_arg_dm}" && ${g_arg_dm} =~ ^/ && ! -d "${g_arg_dm}" ]]; then
		showerr "Domain (${g_arg_dm}) doesn't exist"
		BP_FUNC_RETURN 1
	fi

	# check domain status
	if [[ "${g_arg_cmd}" = @(setup|clean|update|delete) ]]; then
		typeset isalive="no"
		dm_isalive "${g_arg_dm}" isalive
		if [[ "${isalive}" == "yes" ]]; then
			showerr "Domain (${g_arg_dm}) is running, it must be shutdown at first"
			BP_FUNC_RETURN 1 
			###### below processing is more reasonable?? - prompt user to shutdown domain,
			#typeset answer="n"
			#typeset prompt="Domain (${g_arg_dm}) is running, it must be shutdown at first, shutdown it now? (y/n)"
			#read -u ${FDIN} -p "${prompt}" answer
			#if [[ "${answer}" == "y" ]]; then 
			#	dm_shutdown
			#else
			#	BP_FUNC_RETURN 1
			#fi
		fi
	fi 

	# check user
	if [[ "${g_arg_cmd}" = @(adduser|deluser) && -z "${g_arg_user}" ]]; then
		showerr "Please specify the user name with \"name=<user_name>\""
		BP_FUNC_RETURN 1 
	fi 

	###### Action ###############
	eval \${ary_map_cmd_fun[${g_arg_cmd}]} 
	bp_rc=$?  

	## zzy
	#echo "Domain is ${g_workspace}/${DOMAIN_NAME[value]}"

	BP_FUNC_RETURN ${bp_rc}
} 
### function defination end ####

#####################################################
### Main ###
#####################################################
bpmain "${@}"
exit $?
