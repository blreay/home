#!/bin/bash

######################################################################
# This scirpt is used to check if one file include unicode char or any char beyond ascii
######################################################################
file=$1

[[ -z ${file} ]] && echo "usage: ${0##*/} <file>" && exit 1

echo "checking file: $file"

cat $file |  while read a; do 
	((i++))
	if echo $a | grep -oP "[\x80-\xff]" >/dev/null 2>&1; then 
		echo Line-$i inlude unicode-char: $a
		for ((m=0; m<${#a}; m++)); do
			echo ${a:$m:1} | grep -oP "[\x80-\xff]" >/dev/null 2>&1  && printf "pos(%d) %s %d [%s]\n" $m ${a:$m:1} "'${a:$m:1}" "${a:$m-8:16}"
		done
	fi
done

