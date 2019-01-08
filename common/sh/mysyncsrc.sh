#!/bin/ksh

typeset g_appname

function show_usage {
	showerr "Usage: ${g_appname##*/} target_path [-l filelist] [-i ignore_list] [-t]"
    showerr "target_path: target dir,like $MT_ROOT"
    showerr "        -l : file list, seperated by comma"
    showerr "        -i : ignore list, seperated by comma"
    showerr "        -t : test mode, do not copy"
}

function showdbg {
	if [[ $MYDBG == "yes" ]]; then
		showerr ${@:+"$@"}
	fi
}

function showerr {
	echo ${@:+"$@"} >&2
}

function main {
		set +vx
strorig=$@
#str="${strorig#+(* )}"
str="${strorig}"
showdbg zzyorig $strorig
showdbg zzystr $str

while getopts :ti:l: name ${str}; do
showdbg zzyopt $name
case $name in
      i)  iflag=1
	      ival=$OPTARG
        ;;
      l)  lflag=1
	      lval=$OPTARG
        ;;
      t)  tflag=1
        ;;
      \?) show_usage
         exit 0
            ;;
esac
unset OPTARG
done
if [ ! -z $iflag ] ; then
     showdbg "option -i specified"
     showdbg  "$iflag" "$ival"
     showdbg  "$OPTIND"
fi

shift $(($OPTIND -1))
showdbg " shift $(($OPTIND -1))"
target=$1

case ${target} in
("")
	show_usage
	return 1
	;;
(*)
	if [[ ! -d $target ]]; then
			showerr "Path does not exist: $target"
			rerutn 1
	fi
	if [[ -z $lval ]]; then
			filelist=$(mycvs.sh diff 2>/dev/null)
	else
			filelist=$(echo ${lval}|tr "," " ")
	fi
     showdbg  "filelist=$filelist"
	for i in ${filelist}; do
			if [[ ",$ival," = @(*,$i,*) ]]; then
				showerr "$i --> ignored"
				continue
			fi
			if [[ -z $tflag ]]; then
				cp $i $target/$i
			    showerr "$i --> $target/$i"
			else
			    showerr "TEST MODE: $i --> $target/$i"
			fi
	done
	;;
esac 
}

###########################################
g_appname=${0##*/}
set +vx
showdbg "g_appname=$g_appname"
main ${@:+"$@"}
