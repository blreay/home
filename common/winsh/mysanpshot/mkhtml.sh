#!/bin/bash

typeset exe="$MYROOT/tools/disk/Snap2HTML/Snap2HTML.exe"
typeset ifname_in="Local Area Connection"
typeset ifname_out="Wireless Network Connection"
typeset ssid_out="clear-guest"
typeset browserpath="/cygdrive/c/Users/ZHAOZHAN/AppData/Local/Google/Chrome/Application/chrome.exe" 
typeset testurl="http://www.baidu.com"
typeset webauthurl="https://gmp.oracle.com/captcha/files/airespace_pwd_apac.txt"
typeset OPT="-o user $u -o pass $p -o mail $m"
#typeset OPT="-o user $u -o pass $p -o mail $m -v"
## NOTE:   must use "echo -n" otherwise newline is appended ##

function usage {
	echo "Usage: $0 -v <volname> -i <inputpath> -o <outputHTMLfile>"
}

#####################################################################
## Main
while getopts :i:v:o: name; do
	case $name in
	v) volname=$OPTARG
		#shift 1
		;;
	i) in=$OPTARG
		#shift 1
		;;
	o) to=$OPTARG
		#shift 1
		;;
	*) echo "wrong parameter: $name"
		exit 1;
		;;
	esac
done

echo "in=$in"
echo "to=$to"
echo "volname=$volname"
if [[ -z $volname || -z $to || -z $in ]]; then
	usage;
	exit 1;
fi

#exit

exe=$(cygpath $exe)
echo "exe=$exe"
output=$(cygpath -w $to)
echo "output=$output"

#set -vx
#cmd="$exe -path:\"${in}\" -outfile:\"${output}\" -hidden -system"
#eval $cmd
cmd="$exe -path:"${in}" -outfile:"${output}" -hidden -system"
$cmd
exit

echo "function $volname () {" > $output
cat $in | awk '
BEGIN { w=0 };
/\(document\)\.ready\(function\(\)/ {w=0};
// { if (1 == w) print $0;};
/var zzy_showpic = 0;/ {w=1; };
' >> $output
echo "}" >> $output

