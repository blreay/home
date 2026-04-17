#!/bin/sh
#

typeset file=$1
typeset ip=$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
typeset prefix="http://${ip}:38080/os_root"

[[ ${file} =~ ^/ ]] && fullpath=$file || fullpath="$(pwd)/${file}"
echo "${prefix}/${fullpath}" | myyank.sh
echo "${prefix}/${fullpath}"
echo "has been copied to clipboard"
