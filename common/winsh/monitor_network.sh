#!/bin/bash

# v2.5 2018/05/23: remove '\r' from windows command output(after upgrade cygwin, i found \r is appended, it leads to string compare failed
# v2.4 2018/03/27: Optimize Ctrl-C processing
# v2.3 2018/03/26: Add utility routemonitor.exe to monitor route table change
# v2.2 2018/02/23: Support new wifi, add switch to enable/disable sending wifi password
# v2.1 2018/01/17: Add "always" mode, ignore all idle time and weekend
# v2.0 2017/05/15: Don't fetch wifi password from web server every time. save to local file.
#                  Save network status when it's not available, enhanced log. set idle time.
#                  Add test mode
# v1.1 2016/02/14: Add function to add route, add debug
# v1.0 2014/??/??: Initialize and change machine

## resolve the wireless network adapter disconnect pirodly.
# https://downloadmirror.intel.com/26785/eng/Wireless_19.60.0_Driver64_Win10.zip
# 1. Download and save our latest Intel® PROSet/Wireless Software and Drivers for IT Admins: Wireless_19.40.0_Driver64_Win10.zip
# 2. Extract this compressed archive to a known location.
# 3. Open Programs and Features from the Control Panel. Locate and uninstall any entries fro the Intel® PROSet Wireless Software. Choose to discard settings when prompted.
# 4. Open your Device Manager, extend the Network Adapters section. Right click on your Intel(R) Dual Band Wireless-AC 8260 and select to Uninstall. Select to "Delete the drier software for this device" and press OK.  
#5. Press the Windows* Key + R, type "Cleanmgr.exe" and Press OK. Choose to delete your "Temporary Files" and leave everything else unchecked. Press OK.
#6. Reboot your computer.
#7. Open your Device Manager, extend the Network Adapters section. Locate your Intel(R) Dual Band Wireless-AC 8260 and choose to "Update Driver Software." Select to "Browse my computer for driver software," choose the folder where you extracted the IT Admin PROSet earlier as the driver location and include subfolders. Press Next and then OK.


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
function MSG {
	typeset arg="${@}"; typeset msg; typeset funcname=${FUNCNAME[1]}; typeset lineno=${BASH_LINENO[0]}
	printf "%s\n" "${arg}"
} 
############################################## 

## must set LC_ALL=c or LC_ALL=zh_CN.gbk, because all windows command output GBK charset, 
## grep may get "binary data match" result 
export LC_ALL=C
export CURFN="${BASH_SOURCE[$((${#BASH_SOURCE[*]} - 1))]##*/}"

typeset ifname_in="Ethernet"
typeset ifname_out="WLAN"
typeset ifidx_out=
typeset ifidx_in=
typeset ifaddr_in=
typeset ifgw_in=
typeset ifaddr_out=
typeset ifgw_out=
typeset ifdefgw_in="10.182.48.1"
typeset ifdefgw_out="10.182.48.1"

## don't get and send wifi password at daily morning for new wifi, set to 1 if need send daily
typeset g_send_wifi_pwd=0
typeset g_collect_net_status=0
typeset g_flush_dns=0

## flag for if externet network has been connected successfully
typeset g_external_init_done=0


## exec current process again, so that all the output can be written in log file
typeset stdout="/tmp/${CURFN}.log"

## show the history log
#[[ -z "$MON_EXEC" ]] && echo "exec($$) to write log: $stdout" && touch $stdout && MON_EXEC="yes" MYPPID=$$ exec bash "$0" "${@}" "final" 2>&1 | tee -a $stdout && exit 0

typeset applock="/tmp/${CURFN}.lock" 
typeset MON_PLUGIN="$(which ${CURFN}).plugin"
typeset MT_SYS_SIGNAL_TO_TRAP="1 3 4 5 6 7 8 9 10 11 12 13 14 15" 
typeset -i log_save=0
typeset ping_win=$(cygpath "$SYSTEMROOT\System32\PING.EXE")
#trap "printf 'trap signal, will exit\n' ; { mylockfile -u "$applock"; printf 'unlock done\n'; exit 1; }" HUP INT QUIT TSTP KILL ABRT ILL SEGV TERM STOP ${MT_SYS_SIGNAL_TO_TRAP} EXIT


typeset MYWIFIFILE=${MYWIFIFILE:-$HOME/wifiinfo.txt} 

typeset curlcmd="curl 
-H 'Accept-Encoding: gzip, deflate, sdch' 
-H 'Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4' 
-H 'Upgrade-Insecure-Requests: 1' 
-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' 
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' 
-H 'Cache-Control: max-age=0' 
-H 'Connection: keep-alive' 
--compressed 
--insecure 
--verbose 
--ipv4
"

declare -a arydst
arydst=(
www.zhihu.com
www.baidu.com
www.autohome.com
www.hao123.com
www.google.com
mail.google.com
photo.google.com
www.redhat.com
www.vmware.com
www.coolpad.com
www.aliyun.com
www.ubuntu.com
www.gnu.org
www.apache.org
www.bing.com
www.ibm.com
www.intel.com
www.amd.com
www.12306.cn
www.360.cn
hao.360.cn
www.sony.com
www.sohu.com
www.oppo.com
www.jd.com
www.taobao.com.cn
www.tmall.com
www.yahoo.com
www.microsoft.com
www.apple.com
www.sap.com
www.china.com
www.facebook.com
www.cisco.com
www.dell.com
www.fang.com
www.tencent.com
github.com
mp3.baidu.com
www.jlu.edu.cn
stackoverflow.com
www.qq.com
wx.qq.com
qzone.qq.com
www.freecommander.com
mail.139.com
mail.189.com
www.hotmail.com
www.sogou.com
)

typeset sleep_min_min=13
typeset sleep_min_seed=33
typeset sleep_sec_seed=57
typeset curl_timeout=60
typeset logfile=/tmp/switchnetwork.log
typeset curltmpfile=/tmp/curl.${CURFN%.sh}
typeset reconn=0
typeset g_always_check=0
typeset lastday_has_sent 
###########################################################################
function mylockfile {
	DBG "IN: mylockfile"
	typeset ch=
	typeset act="lock"
	typeset lock=
	unset OPTIND
	while getopts :ul ch; do
		DBG "ch=$ch"
		case $ch in
		l) act=lock;;
		u) act=unlock;;
		esac
	done
	shift $(($OPTIND - 1))
	lock=$1
	DBG "act=$act  lock=$lock"
	[[ -z "$lock" ]] && showerr "internal error, need to specify lock file" && return 1
	[[ "$act" == "lock" ]] && { lockfile -1 -r 0 "$lock"; return $?; }
	[[ "$act" == "unlock" ]] && { rm -f "$lock"; return $?; }
}

## only trap EXIT is enough, trap more signal can't work correctly.
#trap 'echo SIGTERM; killall sleep' TERM
#trap 'echo capture SIGINT' INT
## the printf statement always can't output anything ,need more investigtion
#trap "printf 'trap signal: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" INT ABRT
trap "printf 'trap signal INT/ABRT in $$: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" INT ABRT
trap "printf 'trap signal(SIGUSR1): kill all children process\n'; { killpstree.sh $$; echo 'kill done'; echo 'source file:'${MON_PLUGIN}; source ${MON_PLUGIN}; }" USR1
#trap "printf 'trap signal: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" EXIT
#trap "printf 'trap signal EXIT in $$: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" EXIT
#############################################################################
function showdbg_old {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showdbg {
	if [[ "${MYDBG}" == "yes" || "${MYDBG}" == "DEBUG" ]]; then
		typeset msg="${@}"
		typeset funcname=${FUNCNAME[1]}
		typeset file="${BASH_SOURCE[1]:-$0}"
		printf -v msg "$(date +'%Y%m%d %H:%M:%S') %08d [DBG] [${file##*/}][${funcname}] %s\n" "$$" "${msg}"
		printf "%s" "$msg" >&2
		#showerr ${@:+"$@"}
	fi
}
function showerr {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}" >&2
}
function showmsg {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}"
}

function cleannetwork {
###################################
### Clear all the cache of DNS or arp or nbt
showmsg "cleannetwork: Clear all the cache of DNS or arp or nbt and default internal gw"
arp -d "*" &
nbtstat -R &
ipconfig /flushdns &
route delete 0.0.0.0 mask 0.0.0.0 10.182.48.1 &
wait
######################################
}

function traceback {
    set +vx
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#FUNCNAME[@]}
  local -i i=0
  local -i j=0

  DBG "Traceback (last called is first):"
  DBG "--------------------------------------------"
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]:-$0}"
    local line="${BASH_LINENO[$j]}"
    DBG "   $((i-1))  ${function}() in ${file}:${line}" 1>&2
  done
  DBG "--------------------------------------------"
}

function set_init_flag {
	typeset val=$1
	echo "${val}" > /tmp/${g_appname}.flag
}
function get_init_flag {
	typeset vname=$1
	typeset file=/tmp/${g_appname}.flag
	ret="$([[ -f ${file} ]] && cat ${file} || echo 0)"
	eval ${vname}=\"${ret}\"
}

function handle_route_change {
	showmsg "############ begin to handle route table change because of DHCP renew ####"
	while true; do
		get_init_flag g_external_init_done
		DBG "g_external_init_done=${g_external_init_done}"
		if [[ ${g_external_init_done} -eq 0 ]]; then
			DBG "internet initializaiton has not been finished, wait 5 seconds"
			sleep 5 && continue
		else
			DBG "Initialization done, monitor route table"
		fi

		## make sure internet is ready, then begin to monitor route change
		eval $curlcmd --retry 5 --retry-delay 0 --retry-max-time $curl_timeout --max-time $curl_timeout --connect-timeout 5 "http://www.baidu.com" > /dev/null 2>&1
		[[ $? -ne 0 ]] && { 
			showmsg "external network is not ready, don't monitor route change, will retry"; 
			sleep 10 & pid=$!; wait ${pid}; continue; }

		## print route info for 0.0.0.0
		routemonitor "0.0.0.0" >> ${logfile} 2>&1 &
		childpid=$!
		## following statement can't work correctly for Ctrl-C
		#trap 'echo trap INT in function:handle_route_change of $$, kill childpid=${childpid}; kill -9 ${childpid};' INT EXIT
		wait ${childpid}

		if route print -4 0.0.0.0 | grep ${ifdefgw_in} >/dev/null 2>&1; then 
			route delete 0.0.0.0 mask 0.0.0.0 ${ifdefgw_in} >> ${logfile} 2>&1
			showmsg "delete default gw" 2>&1 | tee -a  ${logfile}
		else
			showmsg "OMG: what changed??? switching??" 2>&1 | tee -a ${logfile}
		fi 
	done
	
}

function mysleep {
	typeset t=${1:-3}
	## put sleep processs in background so that signal can be traped 
	sleep $t &
	wait $!
}

function collect_network_status {
	[[ ${g_collect_net_status} -eq 0 ]] && showmsg "g_collect_net_status=${g_collect_net_status}, donot collect" && return 0
	typeset msg=$1
	showmsg "collect network status begin ($msg) -->" >> $logfile 
	netsh interface show interface >> $logfile
	showmsg "ipconfig /all -->" >> $logfile
	ipconfig /all >> $logfile

	typeset dhcpsrv="10.196.255.250"
	showmsg "############ ping dhcp server for wifi: $dhcpsrv"
	testping_output "$dhcpsrv"

	typeset dhcpsrvin="10.254.79.133"
	showmsg "############ ping dhcp server for internal network: $dhcpsrvin"
	testping_output "$dhcpsrvin"

	typeset gwout="10.189.240.1"
	showmsg "############ ping out gw: $gwout"
	testping_output "$gwout"

	typeset dns="206.223.27.2"
	showmsg "############ ping dns server for both wifi and internel network: $dns"
	testping_output "$dns"

	showmsg "############ route talbe is here(N/A now) --> /tmp/route.ng.${curtime}" >> $logfile
	route -4 print >> $logfile
	#route -4 print > /tmp/route.ng.${curtime}
	showmsg "############ nslookup www.baidu.com" >> $logfile
	nslookup www.baidu.com 2>&1 >> $logfile 
	showmsg "collect network status end ($msg) -->" >> $logfile 
}


function testping {
	typeset hosttest=${1:-"www.baidu.com"}
	typeset retrymax=1
	typeset retry=0
	## this loop makes no sense, always run 1 time
	while [[ $retry -lt $retrymax ]]; do
		DBG "ping: retry ($retry/$retrymax)"
		(( retry = retry + 1 ))
		## ping output: 3 packets transmitted, 0 received, 100% packet loss, time 2001ms
		## try 16 times
		/bin/ping $hosttest 4 16 | egrep "(unknown|[^0-9]0[^0-9,]*received)" && DBG "ping: return 1" && return 1
	done
	DBG "ping: return 0"
	return 0
}
function testping_output {
	typeset hosttest=${1:-"www.baidu.com"}
	typeset retrymax=1
	typeset retry=0
	## this loop makes no sense, always run 1 time
	## try 16 times
	/bin/ping $hosttest 4 8 &
	wait $!
	DBG "ping $hosttest: return 0"
	return 0
}

function sendmsg_block {
	[[ "$MYDBG" != "block" ]] && return 1
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	msg="[$(date +'%Y%m%d_%H%M%S')] $msg"
	#cmd /c msg \* /time:3 $msg
	cmd /c msg \* /V /W /time:0 $msg 
	return 0
}
function sendmsg {
	[[ -z $MYDBG ]] && return 1
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	msg="[$(date +'%Y%m%d_%H%M%S')] $msg"
	cmd /c msg \* /time:3 $msg
	#cmd /c msg \* \/V \/W $msg
}

function today_get_and_send {
	typeset today=$(date +'%Y-%m-%d')
	typeset cur_hour=$(date +'%H')
	typeset cur_day=$(date +'%d')
	DBG "today=$today; lastday_has_sent=$lastday_has_sent;  cur_hour=$cur_hour;  cur_day=$cur_day"
	## send at AM 5:00->9:00, because the password is generated at UTC 19:00 (BeiJing time UTC+8 03:00)
	if [[ "x${lastday_has_sent}" != "x$today" && ${cur_hour#0} -eq $(( ${cur_day#0} % 4 + 5)) ]]; then
		if [[ ${g_send_wifi_pwd} -eq 1 ]]; then
			showmsg "Status of $MYWIFIFILE: $(stat -c %y "$MYWIFIFILE")"
			wifi_file_day=$(stat -c %y "$MYWIFIFILE" | awk '{print $1}')
			#wifi_file_day="2017-06-05"
			[[ "$wifi_file_day" != "$today" || ! -f "$MYWIFIFILE" ]] && showmsg "begin to fetch wifi pwd daily morning" && getwifipwd.sh 2>&1 | tee "$MYWIFIFILE"
			## log new password file
			#cat $MYWIFIFILE 2>&1 >> $logfile

			## always try to send again, maybe it has been sent because if wifiinfo is updated, there must be a send action
			## always use sina to send pwd. maybe wifi is not available now so that send fail, but it doesn't matter, the following curl will fail also
			## is send successfully, it means that wifi is available with the old credential, but the newese pwd has been sent by this send action
			DBG "send daily password with -i"
			#source sendwifipwd.sh -i -s "sina" >> $logfile 2>&1 && lastday_has_sent="$today" || showmsg "send password failed, don't set lastday_has_sent"
			## don't write log to switch_network log file
			source sendwifipwd.sh -i -s "sina" 2>&1 && lastday_has_sent="$today" || showmsg "send password failed, don't set lastday_has_sent"
			return 0
		else
			return 1
		fi
	fi
	return 1
}
function today_need_send_mandatory {
	typeset today=$(date +'%Y-%m-%d')
	typeset cur_hour=$(date +'%H')
	if [[ ${cur_hour#0} -eq 6  && "x${lastday_has_sent}" != "x$today" ]]; then
		lastday_has_sent=$today
		return 0
	fi
	return 1
}
function need_disable {
	typeset hour_start=0
	typeset hour_end=5
	typeset day_week=6,7

	unset OPTIND
	while getopts :t:b:e:w: ch; do
		case $ch in
		t) hour_start=$(echo $OPTARG| awk -F "[-]" '{print $1}'); 
		     hour_end=$(echo $OPTARG| awk -F "[-]" '{print $2}');;
		b) hour_start=$OPTARG;;
		e) hour_end=$OPTARG;;
		w) day_week=$OPTARG;;
		esac
	done

	## Over 00:00
	##[[ $hour_end -lt $hour_start ]] && (( hour_end = hour_end + 24 ))

	typeset dayofweek=$(date +'%u')
	typeset cur_hour=$(date +'%H')

	DBG "[$hour_start ... $hour_end] [$day_week] cur_hour=$cur_hour $dayofweek"

	## check if it's weekend
	if [[ $day_week =~ $dayofweek  ]]; then
		showmsg "weekend, do nothing: day[$day_week] hour[$hour_start...$hour_end]"
		return 1
	fi

	## check working time
	## Over 00:00
	##[[ $hour_end -lt $hour_start ]] && (( hour_end = hour_end + 24 ))
	typeset -i disable=0
	if [[ ( $hour_end -ge $hour_start && ${cur_hour#0} -ge $hour_start && ${cur_hour#0} -le $hour_end ) ||
	      ( $hour_end -lt $hour_start && ( ${cur_hour#0} -le $hour_end || ${cur_hour#0} -ge $hour_start ) ) ]]; then
		showmsg "not working time: day[$day_week] hour[$hour_start...$hour_end]"
		return 1
	fi
	return 0
}

function is_external {
	ifgw_out=$(netsh interface ip show addresses name="${ifname_out}" | awk '/Default Gateway/{print $NF}' | tr -d '\r' )
	DBG "Default gateway for $ifname_out: $ifgw_out"
    typeset gwout="${ifgw_out}"
	if [[ -n "$gwout" ]]; then
		#route print|awk '$1=="0.0.0.0" && $3=="'"${gwout}"'" {print $0; exit 100; }'
		route print|awk '$1=="0.0.0.0" && $3=="'"${gwout}"'" { exit 100; }'
		ret=$?
		DBG "ret=$ret"
		[[ ${ret} -eq 100 ]] && return 0 || return 1
	else
		# can't get external gw, treat it as inernet network
		DBG "can't get external gw, treat it as inernet network"
		return 1
	fi
}


############################################
## Main ###
############################################ 
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
	DBG "\$@=$@"
	############################################
	typeset act="$1"

#trap "printf 'trap signal INT/ABRT in main() of $$: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" INT ABRT

	#for test all the destination 
	if [[ "$act" == "test" ]]; then
		## test all destination is OK
		trap '' EXIT
		for i in ${arydst[*]}; do
			{ testping $i >/dev/null 2>&1  && showmsg "OK --> $i" || showmsg "NG --> $i"; }&
		done
		wait
		return 0
	fi
	if [[ "$act" == "reload" ]]; then
		## test all destination is OK
		typeset runpid=$(procps -ef|egrep "$CURFN final" |egrep -v "(vim|grep)" | awk '{print $2}')
		[[ -z "$runpid" ]] && showmsg "No $CURFN process is running" && exit 1
		kill -30 "$runpid"
		exit 0
	fi
	if [[ "$act" == "check" ]]; then
		## check network status
		showmsg "Work in check mode"
	fi
	if [[ "$act" == "always" ]]; then
		## check network status
		g_always_check=1
		showmsg "Work in always check mode"
	fi


	echo "PID:$$ ${@}"
	#set -vx
	#############################################
	#make sure only one instance is running
	#### This is another solution, maybe usefuly in the future
	#echo $(procps -ef | egrep "${0#./}$" | egrep -v "(vim|egrep)")
	#why use 2? because $() will fork current process
	#[[ $(procps -ef | egrep " ${0#./}$" | egrep -v "(vim|egrep)" | wc -l) -gt 2 ]] && echo "another instance is running" && exit 1
	############################################# 
	mylockfile -l "$applock"
	[[ $? -ne 0 ]] && showmsg "another instance is running" && { 
		#echo "pid=$$ MYPPID=$MYPPID"
		#set -vx
		childps=$(killpstree.sh $$ test | awk -F: '{print $1}' | tr '\n' '|' | sed 's/|$//g; s/|/ | /g' )
		typeset runningproc=$(procps -ef | egrep "${0##*/}$" |  egrep -v "(vim|egrep| $$ | ${childps} )")
		[[ -n "$runningproc" ]] && echo $runningproc && trap '' EXIT && exit 1
		[[ -z "$runningproc" ]] && echo "in fact no instance is running, maybe the previous instance crashed"
	}

	## initialize log file
	[[ ${log_save} -eq 1 ]] && {
		[[ -f "$logfile" ]] && cp "$logfile" "${logfile}.bk.$(date +'%Y%m%d_%H%M%S')"
		> $logfile
	}

	set_init_flag 0

	handle_route_change &
	export g_pid_mon_route=$!
	showmsg "g_pid_mon_route=${g_pid_mon_route}"

	typeset login_force=0
	typeset loop=1
	while [[ $loop -ne 0 ]]; do
		#ping www.baidu.com | grep "time=" > /dev/null
		typeset curtime="$(date +'%Y%m%d_%H%M%S')"

		## don't monitor in out-of-working time
		#need_disable -b 14 -e 15 -w 1,7 && { sleep $((10*60 + $RANDOM % 300)); continue; }

		[[ ${g_always_check} -ne 1 ]] && { 
			need_disable -t 20-$(( 4 + $(date +'%d'|sed 's/^0//') % 3)) -w 6,7 || { mysleep $((30*60 + $RANDOM % 300)); continue; }; 
		}

		## mandatory send at everyday 6AM, becasue if login successfully, even the wifi password is changed, current login session is valid up to 10 hours
		## kill rubish process every day
		## as it's stable now, don't need to send mandatory
		#today_need_send_mandatory && reconn=9 && showmsg "mandatory sent everyday at AM6:00" && taskkill /IM qqpetagent.exe
		today_get_and_send && showmsg "mandatory sent everyday at AM(5:00-8:00)" && taskkill /IM qqpetagent.exe

		reconn=0
		typeset n=$(($RANDOM % ${#arydst[*]}))
		typeset dst=${arydst[$n]}

		## clean DNS cache, because i found sometime, 
		## curl report connect error, ping report unknown host, but nslookup return success (result is strange)
		## in debug mode, when i run "ipconfig /flushdns", all become normal, i don't know the root cause,
		## just refresh it by force here
		#cleannetwork

		is_external && {

		##retry 30 time, and each retry deley 1 second.
		eval $curlcmd --retry 5 --retry-delay 0 --retry-max-time $curl_timeout --max-time $curl_timeout --connect-timeout 10 $dst > $curltmpfile 2>&1
		retcurl=$?
		showmsg "RET=$retcurl" >> $curltmpfile
		if [[ $retcurl -ne 0 ]]; then
			reconn=1
			#grep "Connection timed out after" $curltmpfile > /dev/null 2>&1 && echo "timeout!!!"
			showmsg "failed to check $dst at ${curtime} RET=$retcurl"
			cp $curltmpfile ${curltmpfile}.${curtime} 
			grep "name lookup timed out" $curltmpfile > /dev/null 2>&1 && {
				showmsg "name lookup timed out: $dst"
				sendmsg "name lookup timed out: $dst"
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=2
			}
			grep "No route to host" $curltmpfile > /dev/null 2>&1 && {
				showmsg "No route to host: $dst"
				sendmsg "noroute occcured: $dst"
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=3
			}
			grep "Web Authentication Redirect" $curltmpfile >/dev/null 2>&1 && {
				showmsg "Web Authentication Redirect: $dst"
				reconn=1
			}
			grep "Connection timed out" $curltmpfile > /dev/null 2>&1 && {
				showmsg "Connection timed out, Will reconnect: $dst"
				sendmsg "timeout occcured, will reconnect: $dst"
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=4
			}
		else
			### curl return 0, but maybe need to do web authentication or other connection timeout ##
			grep "Connection timed out" $curltmpfile > /dev/null 2>&1 && {
				showmsg "Connection timed out"
				sendmsg "timeout occcured"
				cp $curltmpfile ${curltmpfile}.${curtime}
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=0
			}
			grep "No route to host" $curltmpfile > /dev/null 2>&1 && {
				showmsg "No route to host"
				sendmsg "noroute occcured"
				cp $curltmpfile ${curltmpfile}.${curtime}
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=0
			}
			grep "name lookup timed out" $curltmpfile > /dev/null 2>&1 && {
				showmsg "name lookup timed out"
				sendmsg "name lookup timed out"
				cp $curltmpfile ${curltmpfile}.${curtime}
				[[ "check" == "$act" ]] && sendmsg "external network is unavailable" && exit 0
				reconn=0
			}
			grep "Web Authentication Redirect" $curltmpfile >/dev/null 2>&1 && {
				showmsg "Web Authentication Redirect: $dst"
				cp $curltmpfile ${curltmpfile}.${curtime}
				reconn=10
			} 
		fi 
		true
		## if it's not external network, shift to external directly
		} || { showmsg "it's internal network mode now, switch directly" && reconn=10; }

		## if connect timeout, make sure network is really unavailable by ping dst
		## but if need to do web authorization, don't try ping 
		[[ $reconn -ne 0 && $reconn -ne 10 ]] && { testping $dst && reconn=0 && showmsg "ping $dst success, do not reconnect" || { 
			 newdst="www.baidu.com" && showmsg "ping $dst failed also, try ping $newdst" && testping "$newdst" && reconn=0 && showmsg "ping $newdst success, do not reconnect"; }; }
		[[ $reconn -ne 0 && $reconn -ne 10 ]] && { collect_network_status "flushdns" >> $logfile; 
			sendmsg_block "curl failed for $dst, please check" && exit 1;
			[[ ${g_flush_dns} -eq 1 ]] && cleannetwork; 
			sleep 3; 
			testping $dst && reconn=0 && showmsg "after cleannetwork, ping $dst success, do not reconnect" || showmsg "after cleannetwork ping $dst failed also"; } 

		### switch to outbound network and send pwd### 
		#set -vx
		[[ $reconn -ne 0 ]] && {
			sendmsg_block "network is unavailable, please check it" && exit 1
			### save current network status ###
			collect_network_status "all failed, will reset network" >> $logfile
			## collect status end
			##don't store the error when switch from intranet to internet
			[[ $reconn -ne 10 ]] && ngtime="${ngtime}\n${curtime} $reconn $dst"
			if [[ $login_force -eq 0 && $reconn -ne 10 ]]; then
				showmsg "${curtime} shift to wifi outbound(nologin) begin" >> $logfile
				## -I means ignore wifi login step
				switchnetwork.sh -I out >> $logfile 2>&1
				showmsg "${curtime} shift to wifi outbound(nologin) end" >> $logfile
				login_force=1
			else
				showmsg "${curtime} shift to wifi outbound(withlogin) begin" >> $logfile
				switchnetwork.sh out >> $logfile 2>&1
				showmsg "${curtime} shift to wifi outbound(withlogin) end" >> $logfile
			fi
			check_interval=1
			if [[ ${g_send_wifi_pwd} -eq 1 ]]; then
				source sendwifipwd.sh -i >> $logfile 2>&1 
			fi
		}

		## success
		[[ $reconn -eq 0 ]] && {
			#route print > /tmp/route.ok.${curtime}
			#export g_external_init_done=1
			set_init_flag 1
			login_force=0 
			check_interval=$(( 60 * $(($sleep_min_min + $RANDOM % $sleep_min_seed)) + $(($RANDOM % $sleep_sec_seed)) ))
			echo "[$(date +'%Y%m%d %H:%M:%S')] OK ($dst)\t${loop}\tsleep=$check_interval"
			[[ -n $ngtime ]] && echo "${ngtime#\\n}"
		}
		(( loop = loop + 1 ))
		mysleep $check_interval

		## Ethernet may got the default gw by DHCP automatic assignment
		#if route print -4 0.0.0.0 | grep ${ifdefgw_in}; then route delete 0.0.0.0 mask 0.0.0.0 ${ifdefgw_in}; echo "del default gw"; fi
	done

	## never run here
	mylockfile -u "$applock" 
	return 0
}
#########################################
#following statement will lead to Ctrl-C can't work correctly
#main $@ 2>&1 | tee -a $stdout
main $@ 

