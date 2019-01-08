#!/bin/bash

typeset list=".bash_profile .bashrc .tmux .tmux.conf .vim .vimrc CVS"
typeset nfs=${NFS:-"/nfs/uses/zhaozhan"}
########################################## 
function show_usage {
	showerr "create soft links for: $list"
	showerr "Usage: ${g_appname##*/} [-b]"
    showerr "        -b : backup mode" 
} 
function showdbg {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	echo ${@:+"$@"} >&2
}
function showmsg {
	echo ${@:+"$@"}
}
function clean_tmp {
	rm -f $cookiefn $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $tmp6 $namef $valuef
}
#################################################
function main {
act=""

while getopts :d:s:iobh name ; do
	showdbg getopts:$name
	case $name in
		  d)  olddel=$OPTARG
			;;
		  s)  newdel=$OPTARG
			;;
		  i)  act=login
			;;
		  o)  act=logout
			;;
		  b)  act=backup
			;;
		  h)  show_usage; exit 1;
			;;
		  \?) echo "invalid option $name";
		     	show_usage
			 exit 0
			;;
	esac
	unset OPTARG
done
showdbg "olddel=$olddel newdel=$newdel"

shift $(($OPTIND -1))
showdbg " shift $(($OPTIND -1))"
#[[ -z $act ]] && act="login"
showdbg "act=$act"

[[ -d $nfs ]] || { echo "no NFS" && exit 1; } 
for i in $list; do
	## if backup mode
	[[ X$act == X"backup" ]] && [[ -e $i ]] && mv $i $i.$(date +'%Y%m%d__%H%M%S') && echo "backup: $i" && continue
	[[ -e $i ]] && echo "$i exist" && continue
	[[ X$act != X"backup" ]] && ln -sf $nfs/$i $i
done
}
#############################
g_appname=$0
main "${@}"

