#!/bin/bash

# v2.3 2018/05/23: remove '\r' from windows command output(after upgrade cygwin, i found \r is appended, it leads to string compare failed
# v2.2 2018/03/12: Fix issue of DNS resolve too slow
# v2.1 2018/02/22: support new wifi, new SSID don't need to do wifi login
# v2.0 2017/05/15: Don't fetch wifi password from web server every time. save to local file.
#                  Save network status when it's not available, enhanced log. set idle time.
# v1.1 2016/02/14: Add function to add route, add debug
# v1.0 2014/??/??: Initialize and change machine

##Note:
## sometime, netsh wlan connect command shows that "there is no profile"
## and "netsh wlan export profile" can't work also, in this case
## in the gui of wireless connection, check "auto connect" checkbox of clear-guest
## then the corresponding profile will be created automatically. "netsh wlan show profiles" can work
## 
## The MAC address of network interface can be set to "randam changing" in the setting dialog box of interface
## Don't need to write program to implement this
## 
## 20180312: *** important settings ***
## After upgrade win10, the DNS resolve become very slow (ping and ssh and all network utilities become slow in connect phase)
## root cause: both WLAN and Ethernet have DNS server setted (same). win10 will preferly use the DNS server set in 
## the NIC which has low metiic value (can be confirmed using nslookup). in my original settings, WLAN has low metrics
## so win10 will use WLAN interface to do DNS resolve, but the DSN server list is copied from Ethernet, so WLAN has no direct
## link for these DNS servers. suppose after severl failure upon WLAN interface then try Ethernet interface. so it's slow.
## after makeing Ethernet has more low metrics value, DNS resolve become fast.
## (i also changed [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Linkage]
##  by query the NetCfgInstanceId from
##  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class{4D36E972-E325-11CE-BFC1-08002BE10318}
## ), it made no sense right now, but i changed the metrics upon this changement, not sure if it has impact. (details in my wiz)

###############################################    
# Set bash global option                           
###############################################    
set -o posix                                       
shopt -s expand_aliases                            
shopt -s extglob                                   
shopt -s xpg_echo                                  

## set code page for windows command to english, chinese code page is "936"
chcp.com 437 

## must set LC_ALL=c or LC_ALL=zh_CN.gbk, because all windows command output GBK charset, 
## grep may get "binary data match" result
export LC_ALL=C

#typeset ifname_in="Local Area Connection"
#typeset ifname_out="Wireless Network Connection"
typeset ifname_in="Ethernet"
typeset ifname_out="WLAN"
typeset ifidx_out=
typeset ifidx_in=
typeset ifaddr_in=
typeset ifgw_in=
typeset ifaddr_out=
typeset ifgw_out=
typeset ifdefgw_in="10.182.48.1"
typeset ssid_out_old="clear-guest"
typeset ssid_out="clear-internet"
## new wifi don't need login, set ssid_need_login to 0, set to 1 when using ssid_out_old
typeset ssid_need_login=0
typeset browserpath="/cygdrive/c/Users/ZHAOZHAN/AppData/Local/Google/Chrome/Application/chrome.exe" 
typeset testurl="http://www.baidu.com"
typeset webauthurl="https://gmp.oracle.com/captcha/files/airespace_pwd_apac.txt"
##########################################

function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] string"
    showerr "        -d : specify the delimiter" 
    showerr "        -s : specify the new delimiter" 
} 
function showdbg_old {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showdbg {
	if [[ "$MYDBG" = @(yes|DEBUG) ]]; then
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

function add_specific_route {
	typeset msg=
	typeset addres=
	typeset interface=
	typeset len=
	typeset addr=
	typeset gaddr=
	typeset maskstr=

	#reset getopts environment
	unset OPTIND
	OPTIND=1

	while getopts :m:a:l:i:I name; do
	showdbg "getopts: $name=$OPTARG"
		case $name in
		m) msg=$OPTARG ;;
		a) address=$OPTARG ;;
		l) len=$OPTARG ;;
		i) interface=$OPTARG ;;
		*) echo "wrong parameter: $name"
			return 1
			;;
		esac
	done
	shift $(( OPTIND - 1 )) 

	[[ -z $msg ]] && msg=$address

	showdbg "msg=$msg"
	showdbg "address=$address"
	showdbg "interface=$interface"
	showdbg "len=$len"

	if [[ ! "$address" =~ ^[0-9.]+$ ]]; then
	## for taobao
	#addr=$(nslookup $address 2>/dev/null|sed -f /tmp/sedcmd)
	# there is '09' in the output of windows nslookup
	addr=$(nslookup $address 2>/dev/null | tr '\11' ' ' | egrep "(Address[^:]*:[^:]*$|^ *[0-9.]+ *$)" | awk 'NR==2{print $2==""?$1:$2}')
	else
		addr="$address"
	fi
	showdbg "addr=[$addr]"
	[[ -z "$addr" ]] && showerr "can't get ip address for $address, don't add route" && return 1

	case $len in
	1)  gaddr=$(echo $addr | awk -F "." '{printf("%s.0.0.0", $1)}')
		maskstr="255.0.0.0"
		;;
	2)  gaddr=$(echo $addr | awk -F "." '{printf("%s.%s.0.0", $1, $2)}')
		maskstr="255.255.0.0"
		;;
	3)  gaddr=$(echo $addr | awk -F "." '{printf("%s.%s.%s.0", $1, $2, $3)}')
		maskstr="255.255.255.0"
		;;
	4)  gaddr=$(echo $addr | awk -F "." '{printf("%s.%s.%s.%s", $1, $2, $3, $4)}')
		maskstr="255.255.255.255"
		;; 
	esac

	echo "$msg: $addr -> $gaddr -> $maskstr"
	[[ -n $addr ]] && route add $gaddr mask $maskstr $interface 2>/dev/null

	return 0
}

function get_internal_dns {
	typeset dns=
	## should always use the 10.xxx dns server, other wise 
	#dns=$(netsh interface ip show dns name="${ifname_in}" | grep DHCP |sed 's/.* \([0-9\.]\{1,\}\).*/\1/')
	#[[ -z "$dns" ]] && dns=$(netsh interface ip show dns name="${ifname_in}" | grep DNS |sed 's/.* \([0-9\.]\{1,\}\).*/\1/')
	dns=$(netsh interface ip show dns name="${ifname_in}" | tr -d '\r' | awk '$NF ~ /[0-9.]+/{print $NF}')
	echo "$dns"

	### new solution
	#dns=$(netsh interface ip show dns name="${ifname_in}" | egrep "^ *10\." | awk '{print $1}')
	#[[ -z "$dns" ]] && dns=$(netsh interface ip show dns name="${ifname_in}" | grep DHCP |sed 's/.* \([0-9\.]\{1,\}\).*/\1/')
	#echo "$dns"
}

function cleandns {
###################################
### Clear all the cache of DNS or arp or nbt
arp -d "*"
nbtstat -R
ipconfig /flushdns
######################################
}
#####################################################################
## Main
typeset to=
typeset internal_use=0
unset OPTIND
while getopts :iopsI name; do
	case $name in
	i) to=in;;
	o) to=out;;
	p) to=getpwd;;
	s) to=sendpwd;;
	t) to=test;;
	I) internal_use=1;;
	*) echo "wrong parameter: $name"; exit 1;;
	esac
done

shift $(($OPTIND - 1 ))

if [[ -n $1 && -z $to ]]; then
	to=$1
	echo "$to"
fi

#netsh wlan export profile name="clear-guest" folder=C:\ interface="Wireless Network Connection"
#netsh wlan disconnect interface="Wireless Network Connection"

cat -> /tmp/sedcmd <<-EOF
:begin; {
     /Address/ {
           N;
            /Address.*Aliases/ {
                s/Address: \(.*\)\nAliases.*/\1/g;
                p;
            }
            /Address[^\#]*$/ {
                s/Address: \(.*\)\n.*/\1/g;
                d;
            }
            /^ *[0-9\.]*$/ {
                N;
            }
        }
    d;
} 
EOF


#exit 1

case $to in 
###################################################### 
in)
###################################################### 
showmsg "###### Switch to internal network routing ##########"
#cleandns
[[ ${ssid_need_login} -eq 1 ]] && cleandns

ifgw_out=$(netsh interface ip show addresses name="${ifname_out}" | awk '/Default Gateway/{print $NF}' | tr -d '\r' )
showmsg "Default gateway for $ifname_out: $ifgw_out"

ifgw_in=$(netsh interface ip show addresses name="${ifname_in}" | awk '/Default Gateway/{print $NF}' | tr -d '\r' )
showmsg "Default gateway for $ifname_in: $ifgw_in"
[[ -z "${ifgw_in}" ]] && ifgw_in="${ifdefgw_in}"
## default gw
[[ -n "${ifgw_out}" ]]  && {
#seed not necessary
route delete 0.0.0.0 mask 0.0.0.0 ${ifgw_out} &
}

route add 0.0.0.0 mask 0.0.0.0 ${ifgw_in}
netsh wlan disconnect interface="${ifname_out}"
netsh interface ip set dns "${ifname_out}" DHCP

[[ -n "${ifgw_out}" ]]  && {
## for web-auth: webauth-redirect.oracle.com &
route delete 10.196.255.0 mask 255.255.255.0 ${ifgw_out}  &
}
 
[[ -n "${ifgw_in}" ]] && {
route delete 10.0.0.0    mask 255.0.0.0   ${ifgw_in}  &
route delete 192.0.0.0   mask 255.0.0.0   ${ifgw_in}  &
route delete 152.68.0.0  mask 255.255.0.0 ${ifgw_in}  &
route delete 146.56.0.0  mask 255.255.0.0 ${ifgw_in}  &
route delete 148.87.0.0  mask 255.255.0.0 ${ifgw_in}  &
route delete 141.0.0.0   mask 255.0.0.0   ${ifgw_in}  &
route delete 144.0.0.0   mask 255.0.0.0   ${ifgw_in}  &
route delete 209.0.0.0   mask 255.0.0.0   ${ifgw_in}  &
route delete 130.35.0.0  mask 255.255.0.0 ${ifgw_in}  &
}
wait
#route delete 74.125.0.0  mask 255.255.0.0 ${ifgw_in} #google
route print -4
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v logout
;;
######################################################## 
out)
#########################################################
showmsg "###### Switch to outside network routing ##########"
[[ ${ssid_need_login} -eq 1 ]] && cleandns

## sometimes, even wifi connect successfully, the default gw can't be retrieved. so retry here

#netsh wlan disconnect interface="${ifname_out}"
CMD="netsh wlan connect ssid=\"$ssid_out\" name=\"$ssid_out\""
echo ${CMD}
${CMD}
showmsg "netsh wlan connect: $?"

typeset retry=0
typeset retrymax=20
typeset retrysleep=3
while [[ ${retry} -lt ${retrymax} ]]; do
	(( retry++ ))

	typeset ifname_in_dns=$(get_internal_dns)
	showmsg "DSN server: $ifname_in_dns"
	[[ -z $ifname_in_dns ]] && echo "can not get DNS server of ${ifname_in}" && sleep ${retrysleep} && continue

	ifgw_in=$(netsh interface ip show addresses name="${ifname_in}" | tr -d '\r' | awk '/Default Gateway/{print $NF}' )
	[[ -z "${ifgw_in}" ]] && ifgw_in="${ifdefgw_in}"
	showmsg "Default gateway for $ifname_in: $ifgw_in"
	[[ -z "${ifgw_in}" ]] && echo "can not get default gateway for ${ifname_in}" && sleep ${retrysleep} && continue

	## get other information 
	ifidx_out=$(netsh interface ip show interface interface="${ifname_out}" | tr -d '\r' | awk '/IfIndex/{print $NF}')
	showmsg "interface index for $ifname_out: $ifidx_out"
	[[ -z "${ifidx_out}" ]] && echo "can not get interface index for ${ifname_out}" && sleep ${retrysleep} && continue
	ifidx_in=$(netsh interface ip show interface interface="${ifname_in}" | tr -d '\r' | awk '/IfIndex/{print $NF}')
	showmsg "interface index for $ifname_in: $ifidx_in"
	[[ -z "${ifidx_in}" ]] && echo "can not get interface index for ${ifname_in}" && sleep ${retrysleep} && continue

	cmd="netsh interface ip show addresses name=\"${ifname_out}\""
	echo $cmd
	$cmd

	ifgw_out=$(netsh interface ip show addresses name="${ifname_out}" | tr -d '\r' | awk '/Default Gateway/{print $NF}' )
	showmsg "Default gateway for $ifname_out: $ifgw_out"
	[[ -z "${ifgw_out}" ]] && echo "can not get default gateway for ${ifname_out}" && sleep ${retrysleep} && continue 

	## all successed, don't retry again
	break
done
[[ ${retry} -gt ${retrymax} ]] && echo "can't get network info correctly, check connection" && exit 1

#netsh interface ip set dns "${ifname_out}" static "${ifname_in_dns}" 
## add more DNS server
#set -vx
typeset -a arydns=($ifname_in_dns);
for((i=0; i<${#arydns[*]}; i++)); do
	showmsg "Add DSN server#$i: ${arydns[$i]}"
	[[ $i -eq 0 ]] && netsh interface ip set dns "${ifname_out}" static "${arydns[$i]}" 
	[[ $i -ne 0 ]] && netsh interface ip add dns name="${ifname_out}" address="${arydns[$i]}" validate=no
done
#set +vx
showmsg "configure route table for external network: default gw"


##NOTE:
## I found the default route table's metric always be changed, so that the 
## prefered gw's metric maybe lower than the second gw
## solution is to set the metric to be a fixed value through IPV4 
## advance setting page of ther network adaptor, out_if to be 10, in_if to be 30
## 
## my issue was: after about 1-3 hours, internet can't be accessed
## compared route table, there are 2 defaut gw appeard, the metric of internal adapter is lower than wifi adaptor
## this is caused by "ipconfig /renew", DHCP server will renew ip every X(6?) hours automatically.
## to obtain interface index: netsh interface ip show interface
#
#  1          50  4294967295  connected     Loopback Pseudo-Interface 1
#  7          50        1500  connected     Local Area Connection
# 12           0        1500  connected     Wireless Network Connection
# 19           5        1500  disconnected  xxx

## default gw

## make this default gw available but adjust the metric value in the advance setting dialogbox
## make no sensen above action, must delete it
route delete 0.0.0.0 mask 0.0.0.0 ${ifgw_in} &

route delete 0.0.0.0 mask 0.0.0.0 ${ifgw_out} if ${ifidx_out} &
route delete 10.182.0.0 mask 255.255.0.0 ${ifgw_out}  &
wait

CMD="route add 0.0.0.0 mask 0.0.0.0 ${ifgw_out} if ${ifidx_out} metric 30"
echo ${CMD}
${CMD}
CMD="netsh interface ipv4 set interface ${ifidx_out} metric=30"
echo ${CMD}
${CMD}
CMD="netsh interface ipv4 set interface ${ifidx_in} metric=20"
echo ${CMD}
${CMD}

showmsg "configure route table for external network"
## for web-auth: webauth-redirect.oracle.com
## in some issue: can't open login page, following route table become wrong. gw is ${ifgw_out}, but interface become ip of ethernet network ip
route add 10.196.255.0 mask 255.255.255.0 ${ifgw_out} 

## for oracle internal network
route add 10.0.0.0    mask 255.0.0.0   ${ifgw_in} &
route add 10.182.0.0  mask 255.255.0.0 ${ifgw_in} metric 1 &
#route change 10.182.0.0    mask 255.255.0.0   ${ifgw_in} metric 10  &
#route add 10.182.0.0 mask 255.255.0.0 ${ifgw_out} metric 35
route add 192.0.0.0   mask 255.0.0.0   ${ifgw_in}   &
route add 152.68.0.0  mask 255.255.0.0 ${ifgw_in}   &
route add 156.151.0.0 mask 255.255.0.0 ${ifgw_in}   &
route add 146.56.0.0  mask 255.255.0.0 ${ifgw_in}  &
#route add 74.125.0.0 mask 255.255.0.0 ${ifgw_in} #google  &
route add 148.87.0.0  mask 255.255.0.0 ${ifgw_in}   &
route add 140.0.0.0   mask 255.0.0.0   ${ifgw_in}   &
route add 141.0.0.0   mask 255.0.0.0   ${ifgw_in}   &
route add 144.0.0.0   mask 255.0.0.0   ${ifgw_in}   &
route add 209.0.0.0   mask 255.0.0.0   ${ifgw_in}   &
route add 130.35.0.0  mask 255.255.0.0 ${ifgw_in}   &
#route DNS server, must use the internal DNS server  &
for((i=0; i<${#arydns[*]}; i++)); do
	route add "${arydns[$i]}" mask 255.255.255.255 ${ifgw_in} metric 1  &
done
## for taobao
##addr=$(nslookup login.taobao.com 2>/dev/null|grep Address|awk '{print $2}'|tail -1)
#addr=$(nslookup login.taobao.com 2>/dev/null|sed -f /tmp/sedcmd)
#gaddr=$(echo $addr | awk -F "." '{printf("%s.%s.0.0", $1, $2)}')
#echo "taobao_login: $addr -> $gaddr"
#[[ -n $addr ]] && route add $gaddr mask 255.255.0.0 ${ifgw_out}

#addr=$(nslookup www.taobao.com 2>/dev/null|sed -f /tmp/sedcmd)
#gaddr=$(echo $addr | awk -F "." '{;printf("%s.%s.0.0", $1, $2)}')
#echo "taobao_www: $addr -> $gaddr"
#[[ -n $addr ]] && route add $gaddr mask 255.255.0.0 ${ifgw_out}
#addr=$(nslookup wx.qq.com 2>/dev/null|sed -f /tmp/sedcmd)
	#gaddr=$(echo $addr | awk -F "." '{printf("%s.%s.0.0", $1, $2)}=<')
#echo "weixin_web: $addr -> $gaddr"
#[[ -n $addr ]] && route add $gaddr mask 255.255.0.0 ${ifgw_out}
#route print -4

## for internal
#add_specific_route -i "$ifgw_in" -m "" -l 2 -a "webauth-redirect.oracle.com" &
add_specific_route -i "$ifgw_in" -m "" -l 2 -a "webauth-redirect.oracle.com" &
add_specific_route -i "$ifgw_in" -m "" -l 2 -a "login.oracle.com" &

## for external
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "github.com" &
add_specific_route -i "$ifgw_out" -m "" -l 2 -a "wx.qq.com" &
add_specific_route -i "$ifgw_out" -m "" -l 2 -a "www.taobao.com" &
add_specific_route -i "$ifgw_out" -m "" -l 2 -a "login.taobao.com" &
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "cygwin.com" &
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "www.jd.com" &
add_specific_route -i "$ifgw_out" -m "" -l 2 -a "www.wordpress.com" &
add_specific_route -i "$ifgw_out" -m "" -l 2 -a "www.apache.org" &
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "www.aliyun.com" & 
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "cf.aliyun.com" & 
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "www.linkedin.com" &
#add_specific_route -i "$ifgw_out" -m "" -l 3 -a "99yp.cc" & 

## for special APP in android
## Yingyongbao
add_specific_route -i "$ifgw_out" -m "" -l 3 -a "140.206.160.242" &

showmsg "begin to wait route add command finish"
wait
showmsg "route add done"
showmsg "begin to do wifi login"


#"$browserpath" -- "$testurl" &
#"$browserpath" -- "$webauthurl" &

#java -jar D:\Program\Java\wifilogin\wifilogin.jar -v login
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v reset

#This one can also work, but it's slow, because it will run a simulated browser
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v login
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v https_login

## Above java program is lost because HD crash, i reimplemented it with shell script by curl
if [[ $internal_use -eq 0 && $ssid_need_login -eq 1 ]]; then
	wifilogin.sh -i
else
	## test outbound work is ready or not
	##wifilogin.sh -i
	showmsg "internal_use=$internal_use, do nothing, don't call wifilogin.sh"
fi
;;
###################################################### 
getpwd)
###################################################### 
showmsg "###### Get wifi password ##########"
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -i getpwd 
getwifipwd.sh
;;
###################################################### 
sendpwd)
###################################################### 
showmsg "###### Send wifi password ##########"
sendwifipwd.sh
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v sendmail
;;
https_login)
###################################################### 
showmsg "###### login with HTTPS request ##########"
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v https_login
wifilogin.sh -i
;;
https_logout)
###################################################### 
showmsg "###### logout with HTTPS request ##########"
#java -jar D:\\Program\\Java\\wifilogin\\wifilogin.jar -v https_logout
wifilogin.sh -o
;;
*)
showmsg "syntax wrong"
showmsg "Usage: switchnetwork.sh in | out | getpwd | sendpwd | https_login | https_logout"
;;
esac

