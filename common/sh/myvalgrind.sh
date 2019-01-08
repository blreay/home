#!/bin/ksh

typeset g_appname

function show_usage {
	showerr "Usage: ${g_appname##*/} [-p parameters] [-f logfile] exefile"
    showerr "target_path: target dir,like $MT_ROOT"
    showerr "        -p : parameters for exefile"
    showerr "        -f : log file"
    showerr "        -t : test mode, show cmd line only"
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
#strorig=$@
#str="${strorig}"
#showdbg zzyorig $strorig
#showdbg zzystr $str
while getopts :p:f:t name; do
showdbg zzyopt $name
case $name in
      p)  pflag=1
	      pval=$OPTARG
        ;;
      f)  fflag=1
	      fval=$OPTARG
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
	exefile=$(which $target)
	if [[ ! -f $exefile ]]; then
			showerr "Path does not exist: $target: $exefile"
			rerutn 1
	fi
	#valgrind --log-file=output.file --leak-check=yes --tool=memcheck artjesadmin
	typeset mycmd="valgrind ${fval:+--log-file=$fval} --leak-check=yes --tool=memcheck $exefile $pval"
	showerr "cmdline: $mycmd"
	if [[ $tflag -ne 1 ]]; then
		$mycmd
	fi
	;;
esac 
}

###########################################
g_appname=${0##*/}
set +vx
showdbg "g_appname=$g_appname"
main ${@:+"$@"}
