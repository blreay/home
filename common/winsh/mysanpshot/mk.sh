#!/bin/bash

typeset ifname_in="Local Area Connection"
typeset ifname_out="Wireless Network Connection"
typeset ssid_out="clear-guest"
typeset browserpath="/cygdrive/c/Users/ZHAOZHAN/AppData/Local/Google/Chrome/Application/chrome.exe" 
typeset testurl="http://www.baidu.com"
typeset webauthurl="https://gmp.oracle.com/captcha/files/airespace_pwd_apac.txt"
typeset picexepath="D:\mydisk\tools\application\pic\XnView-win-full\XnView\xnview.exe"
#typeset OPT="-o user $u -o pass $p -o mail $m -v"
## NOTE:   must use "echo -n" otherwise newline is appended ##

function usage {
	echo "Usage: $0 -v <volname> -i <inputfile> -o <outputdir>"
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


#output=$to/${volname}.js
output=$to
echo "output=$output"

tmpfile="$PWD/tmp.html"
rm -rf $tmpfile
./mkhtml.sh -v dumy -i "$in" -o "$tmpfile"
./genjs.sh -i "$tmpfile" -v "$volname" -o "$output"

echo "start: $picexepath"
`cygpath "$picexepath"`


#rm -rf $tmpfile
