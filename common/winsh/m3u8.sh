#!/bin/bash

###############################################
## convert m3u8 file to one MP4 file
##
## Note: 20160617 zzy
##
## Usage:
## 1. cd the folder which include the subfolder which including *.ts file
## 2. run m3u8.sh <folder_name>
## 3. the mp4 file will be generated at current dir: <folder_name>.mp4
################################################

typeset tmpcombine=zzy.combine.ts
typeset opedir=

#####################################################################
## Main
while getopts :fp:ls name; do
	case $name in
	p) lport=$OPTARG
		echo "aa"
		;;
	f) force=1
		;;
	*) echo "wrong parameter: $name"
		exit 1;
		;;
	esac
done

opedir=${1##*/}
[[ -z $opedir ]] && echo "opedir is not defined" && exit 1
cd $opedir

#set -vx
## find file list
/bin/rm -f $tmpcombine
flist=$(ls *.ts| sort -t "." -k 1 -n)
## can't find *.ts file, suppose filename has no .ts extension
[[ $? -ne 0 || -z $flist ]] && flist=$(/bin/ls | egrep  "^[0-9]+$" | sort -n)
echo "file list: $flist"

### merge ts file
[[ -n $flist ]] && cat $flist > $tmpcombine || { echo "file list is NULL" && exit 1; }

### convert ts to MP4
echo "convert TS to MP4"
ffmpeg -i $tmpcombine -acodec copy -vcodec copy -bsf aac_adtstoasc ../${opedir}.mp4 && /bin/rm $tmpcombine

cd -
echo "================================================="
echo "mp4file is generated: ${opedir}.mp4"

