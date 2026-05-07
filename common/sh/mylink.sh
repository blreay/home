#!/bin/bash
#
#set -vx

typeset view_mode=0
while getopts v ch; do
  case $ch in
    v) view_mode=1;;
  esac
done
shift $((OPTIND-1))
typeset file=$1

typeset ip=$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
typeset prefix="http://${ip}:38080/os_root"
typeset prefix_view="http://${ip}:38080/myhome/git/bashttpd/md_viewer.html?file="

[[ ${file} =~ ^/ ]] && fullpath=$file || fullpath="$(pwd)/${file}"
typeset url="${prefix}/${fullpath}"
[[ ${view_mode} -eq 1 ]] && url="${prefix_view}/os_root/${fullpath}"

echo "${url}" | myyank.sh
echo "${url}"
echo "has been copied to clipboard"
