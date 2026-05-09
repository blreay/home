#!/bin/bash
#
#set -vx

typeset view_mode=0
typeset send_mode=0
while getopts vs ch; do
  case $ch in
    v) view_mode=1;;
    s) send_mode=1;;
  esac
done
shift $((OPTIND-1))
typeset file=$1

if [[ $send_mode -eq 0 ]]; then
	typeset ip=$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
	typeset prefix="http://${ip}:38080/os_root"
	typeset prefix_view="http://${ip}:38080/myhome/git/bashttpd/md_viewer.html?file="

	[[ ${file} =~ ^/ ]] && fullpath=$file || fullpath="$(pwd)/${file}"
	typeset url="${prefix}/${fullpath}"
	[[ ${view_mode} -eq 1 ]] && url="${prefix_view}/os_root/${fullpath}"
else
	typeset ip=$MYVM
	scp $file zhaoyong.zzy@$ip:~/docs/
	fullpath=/home/zhaoyong.zzy/docs/${file##*/}
	#typeset url="http://${MYVM}:38080/myhome/git/bashttpd/md_viewer.html?file=${remote_path}"
	#[[ ${view_mode} -eq 1 ]] && url="${prefix_view}/os_root/${fullpath}"
fi

typeset prefix="http://${ip}:38080/os_root"
typeset prefix_view="http://${ip}:38080/myhome/git/bashttpd/md_viewer.html?file=/os_root"

#[[ ${file} =~ ^/ ]] && fullpath=$file || fullpath="$(pwd)/${file}"
typeset url="${prefix}${fullpath}"
[[ ${view_mode} -eq 1 ]] && url="${prefix_view}${fullpath}"

echo "${url}" | myyank.sh
echo "${url}"
echo "has been copied to clipboard"
[[ ${view_mode} -eq 1 ]] && url="${prefix}${fullpath}" && echo "${url}"
