#!/bin/bash

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

## must set LC_ALL=c or LC_ALL=zh_CN.gbk, because all windows command output GBK charset, 
## grep may get "binary data match" result
export tcexe="D:\mydisk\tools\disk\TrueCrypt 7.1a\TrueCrypt.exe"
export vcexe="D:\mydisk\tools\disk\VeraCrypt\VeraCrypt-x64.exe"
export myvolroot="D:\zzy\mydisk"
export myvolroot_all="C:\zzy\@@@@\360disk"
export g_force_use_veracrypt=1

export LC_ALL=C
export CURFN="${BASH_SOURCE[$((${#BASH_SOURCE[*]} - 1))]##*/}"
export tcexe="$(cygpath "${tcexe}")" 
export vcexe="$(cygpath "${vcexe}")" 

typeset applock="/tmp/${CURFN}.lock" 
typeset MON_PLUGIN="$(which ${CURFN}).plugin"
typeset MT_SYS_SIGNAL_TO_TRAP="1 3 4 5 6 7 8 9 10 11 12 13 14 15" 
#trap "printf 'trap signal, will exit\n' ; { mylockfile -u "$applock"; printf 'unlock done\n'; exit 1; }" HUP INT QUIT TSTP KILL ABRT ILL SEGV TERM STOP ${MT_SYS_SIGNAL_TO_TRAP} EXIT

function show_usage {
	showerr "Usage: ${g_appname##*/} -m|-u [[-v volnum] all]"
    showerr "        -m: mount" 
    showerr "        -u: umount"
    showerr "        -r: run application only"
    showerr "        -v: volumn numser, such as 23, only work with 'all'"
} 

function traceback {
    set +vx
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#FUNCNAME[@]}
  local -i i=0
  local -i j=0

  showdbg "Traceback (last called is first):"
  showdbg "--------------------------------------------"
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]:-$0}"
    local line="${BASH_LINENO[$j]}"
    showdbg "   $((i-1))  ${function}() in ${file}:${line}" 1>&2
  done
  showdbg "--------------------------------------------"
}

function mysleep {
	typeset t=${1:-3}
	## put sleep processs in background so that signal can be traped 
	sleep $t &
	wait $!
} 
function showdbg {
	if [[ ${MYDBG^^} =~ ^(YES|DEBUG)$ ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}" >&2
}
function showmsg {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}"
} 

function sendmsg_block {
	[[ "$MYDBG" != "block" ]] && return 1
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	msg="[$(date +'%Y%m%d_%H%M%S')] $msg"
	#CMD /c msg \* /time:3 $msg
	CMD /c msg \* /V /W /time:0 $msg 
	return 0
}
function sendmsg {
	[[ -z $MYDBG ]] && return 1
	typeset msg
	[[ -z $1 ]] && msg="All actions have been done." || msg=$1
	msg="[$(date +'%Y%m%d_%H%M%S')] $msg"
	CMD /c msg \* /time:3 $msg
	#CMD /c msg \* \/V \/W $msg
} 
function mylockfile {
	typeset ch=
	typeset act="lock"
	typeset lock=
	unset OPTIND
	while getopts :ul ch; do
		showdbg "ch=$ch"
		case $ch in
		l) act=lock;;
		u) act=unlock;;
		esac
	done
	shift $(($OPTIND - 1))
	lock=$1
	showdbg "act=$act  lock=$lock"
	[[ -z "$lock" ]] && showerr "internal error, need to specify lock file" && return 1
	[[ "$act" == "lock" ]] && { lockfile -1 -r 0 "$lock"; return $?; }
	[[ "$act" == "unlock" ]] && { rm -f "$lock"; return $?; }
}

############################################
## Main ###
############################################

function mount_main {


## only trap EXIT is enough, trap more signal can't work correctly.
#trap 'echo SIGTERM; killall sleep' TERM
trap 'echo capture SIGINT; mylockfile -u "$applock"; exit 1 ' INT

trap "printf 'trap signal(SIGUSR1): kill all children process\n'; { killpstree.sh $$; echo 'kill done'; echo 'source file:'${MON_PLUGIN}; source ${MON_PLUGIN}; }" USR1
#trap "printf 'trap signal: kill all children process\n'; { killpstree.sh $$; echo 'kill done'; mylockfile -u "$applock"; printf 'unlock done($$)\n'; exit 0; }" EXIT 
#echo "PID:$$ ${@}"

	typeset act="mount"
	typeset argvol
	unset OPTIND

	while getopts :mv:urh ch; do
		showdbg "ch=$ch"
		case $ch in
		m) act="mount";;
		u) act="unmount";;
		r) act="runapp";;
		v) argvol="$OPTARG";;
		h) show_usage; exit 0;;
		#?) show_usage; mylockfile -u "$applock"; exit 1;;
		?) showerr "invalid option: $ch"; show_usage; exit 1;;
		esac
	done
	shift $(($OPTIND - 1))
	[[ -n "$1" ]] && [[ "$1" != "all" ]] && { showerr "invalid command: $1"; show_usage; exit 1; }
	[[ "$1" == "all" ]] && myvolroot="$myvolroot_all"
	showdbg "act=$act \$1=$1"

	#make sure only one instance is running 
	mylockfile -l "$applock"
	[[ $? -ne 0 ]] && showmsg "another instance is running" && { 
		#echo "pid=$$ MYPPID=$MYPPID"
		procps -ef | egrep "${0#./}$" | egrep -v "(vim|egrep| $$ | $MYPPID )"
		trap '' EXIT
		exit 1
	}

	case $act in
		("mount") 
			typeset pwd=
			#read -s -p "Please input password:" pwd
			#echo
			typeset imax=$(printf "%d" "'y")
			typeset imin=$(printf "%d" "'g")
			for vol in $([[ -z "$argvol" ]] && ls $(cygpath "$myvolroot")/MyVol* || cygpath "$myvolroot\MyVol.4G.$argvol"); do
				showdbg "volumn:$vol"
				[[ ! -f $vol ]] && showerr "File doesn't exist: $vol" && continue
				typeset dl=
				typeset d2=
				typeset ch=
				typeset dl=
				d1=$(ls /cygdrive)
				for((i=$imax; i>=$imin; i--)); do
					ch=$(printf \\x`printf %x $i`)
					[[ ! $d1 =~ $ch ]] && dl=$ch && imax=$i && break
				done
				[[ -z "$pwd" ]] && read -s -p "Please input password:" pwd && echo
				if [[ $g_force_use_veracrypt -ne 1 ]]; then
					"${tcexe}" /q /s /p "$pwd" /l ${dl} /v "$(cygpath -w "$vol")"
				else
					"${vcexe}" /truecrypt /q /s /p "$pwd" /l ${dl} /v "$(cygpath -w "$vol")"
				fi
				dl=${dl^}
				#echo $vol    ${dl:-"**ERROR**"}
				printf "%-60s %s\n" "$vol" ${dl:-"**ERROR**"}
			done
			"${tcexe}" &

			### run verecrypt
			typeset imax=$(printf "%d" "'z")
			typeset imin=$(printf "%d" "'g")
			for vol in $([[ -z "$argvol" ]] && ls $(cygpath "$myvolroot")/vol32g* || cygpath "${myvolroot}\vol32g.${argvol}"); do
				showdbg "volumn:$vol"
				[[ ! -f $vol ]] && showerr "File doesn't exist: $vol" && continue
				typeset dl=
				typeset d2=
				typeset ch=
				typeset dl=
				d1=$(ls /cygdrive)
				for((i=$imax; i>=$imin; i--)); do
					ch=$(printf \\x`printf %x $i`)
					[[ ! $d1 =~ $ch ]] && dl=$ch && imax=$i && break
				done
				[[ -z "$pwd" ]] && read -s -p "Please input password:" pwd && echo
				#set -vx
				"${vcexe}" /q /s /p "${pwd}" /l ${dl} /v "$(cygpath -w "$vol")"
				dl=${dl^}
				#echo $vol    ${dl:-"**ERROR**"}
				printf "%-60s %s\n" "$vol" ${dl:-"**ERROR**"}
			done
			"${vcexe}" &
			;;
		("unmount")
				[[ $g_force_use_veracrypt -ne 1 ]] && "${tcexe}" /q /d
				"${vcexe}" /q /d
			;;
		("runapp")
				#[[ $g_force_use_veracrypt -ne 1 ]] && "${tcexe}" /q /d
				"${vcexe}" &
			;;
		(*) showusage; exit 1;;
	esac 

## never run here
mylockfile -u "$applock" 
exit 0
}

##################################
typeset g_appname="mount_truecrypt.sh"
mount_main "${@}"
