#!/bin/bash

maxb=$((1024*1024))    # default 1MiB
out="log"              # output file name
width=3                # width: log.001, log.002
while getopts "b:o:w:" opt; do
  case $opt in
    b ) maxb=$OPTARG;;
    o ) out="$OPTARG";;
    w ) width=$OPTARG;;
    * ) echo "Unimplented option."; exit 1
  esac
done
shift $(($OPTIND-1))

IFS='\n'              # keep leading whitespaces
if [ $# -ge 1 ]; then # read from file
  cat $1
else                  # read from pipe
  while read arg; do
    echo $arg
  done
fi | awk -v b=$maxb -v o="$out" -v w=$width '{
    n+=length($0); print $0 > sprintf("%s.%0.*d",o,w,n/b)}'
