#!/bin/ksh

typeset g_appname

function show_usage {
	showerr "Usage: ${g_appname##*/} command [-l] [-t] [-m msg]"
    showerr "   command : diff [-l] | add [-t] | rm [-t]|commit [-t] [-m msg]" 
    showerr "        -l : show result in one line" 
    showerr "        -t : just list the target files without real action"
    showerr "           : rm/commit will read file list from stdin"
}

function showdbg {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
}

function showerr {
	echo ${@:+"$@"} >&2
}

function cvs_add_one_folder {
	typeset dirname="$1"
	typeset msg="$2"
	typeset thispwd="$(pwd)"
	showdbg "$0: dirname=$dirname msg=$msg thispwd=$thispwd" 
	[[ -z $dirname ]] && echo "[$0] dir name is missing" && return 1
	cd $dirname
	cvs add -kb -m "$msg" *
	typeset list="$(ls -l | grep "^d" | awk '{print $9}' | grep -v CVS)"
	showdbg "$0: list=$list"
	[[ ! -z $list ]] && {
		typeset subdir=""
		for subdir in $list; do
			showdbg "$0: subfolder dirname=$subdir"
			cvs_add_one_folder "$subdir" "$msg"
		done
	}
	cd "$thispwd"
}

############################################################
function main {
if [[ -z $CVSLOG ]]; then
	showerr "CVSLOG not set"
	exit -1
fi
strorig="${@}"
now=$(date +'%Y%m%d_%H%M%S')
command=$1
shift 1
str="${strorig#+(* )}"
mval="null"
showdbg zzyorig $strorig
showdbg zzystr $str

#set -vx
#while getopts :m:tl name ${str}; do
while getopts :m:r:tl name; do
	showdbg zzy:$name
	case $name in
		  l)  lflag=1
			;;
		  t)  tflag=1
			;;
		  m)  mval=${OPTARG:-null};
			;;
		  r)  rval=${OPTARG:-null};
			;;
		  \?) echo "invalid option $name";
		     	show_usage
			 exit 0
			;;
	esac
	unset OPTARG
done
showdbg "lflag=$lflag;tflag=$tflag;mval=$mval"

if [ ! -z $lflag ] ; then
     showdbg "option -l specified"
     showdbg  "$aflag"
     showdbg  "$OPTIND"
fi

shift $(($OPTIND -1))
showdbg " shift $(($OPTIND -1))"

if [[ $command = @(add|rm|commit) ]]; then
	echo "$now -------------------------------------------------------------" >> $CVSLOG
	echo "${strorig}" >> $CVSLOG
fi

case ${command} in
("")
	show_usage
	return 1
	;;
(diff)
	showdbg "cvs diff"
	if [[ -z $lflag ]]; then
		cvs diff ${rval:+-r $rval} 2>/dev/null|grep "^Index: "|awk '{print $2}'
	else
		cvs diff ${rval:+-r $rval} 2>/dev/null|grep "^Index: "|awk '{printf("\"%s\" ",$2)} END{printf("\n")}'
	fi
	;;
(add)
	showdbg "cvs add: tflag=$tflag"
	for i in $(cvs diff 2>/dev/null|egrep "^\?"|awk '{print $2}'); do 
			showerr $i
			if [[ ! -z $tflag ]]; then
					continue
			fi
			cvs add -kb ${mval:+-m "$mval"} $i 2>&1  | sed 's/^/'"$now"' '"$mval"' -->  /g' | tee -a $CVSLOG
			cvs commit ${mval:+-m "$mval"} $i 2>&1  | sed 's/^/'"$now"' '"$mval"' -->  /g' | tee -a $CVSLOG
	done
	;;
(add_dir)
	dirname=$1
	[[ -z $dirname ]] && echo "dir name is missing" && return 1;
	showdbg "cvs add_dir: tflag=$tflag dirname=$dirname"
	cvs_add_one_folder  $dirname $mval
	;;
(rm)
	showdbg "cvs rm: tflag=$tflag"
	while read fn; do
		fn=${fn#./}
		echo ${fn}
		if [[ ! -z $tflag ]]; then
				continue
		fi
		cvs rm -f $fn 2>&1  | sed 's/^/'"$now"' '"$mval"' -->  /g' | tee -a $CVSLOG
		cvs commit ${mval:+-m "$mval"} $fn 2>&1  | sed 's/^/'"$now"' '"$mval"' -->  /g' | tee -a $CVSLOG
	done
	;;
(commit)
	showdbg "cvs commit: tflag=$tflag"
	while read fn; do
		fn=${fn#./}
		echo ${fn}
		if [[ ! -z $tflag ]]; then
				continue
		fi
		cvs commit ${mval:+-m "${mval}"} $fn 2>&1 | sed 's/^/'"$now"' '"$mval"' -->  /g' | tee -a $CVSLOG
	done
	;;
(*)
	showerr "Unknown command: $command "
	show_usage
	return 1
	;;
esac 


}

###########################################
g_appname=${0##*/}
showdbg "g_appname=$g_appname"
main ${@:+"$@"}

