#!/bin/bash
#
#set -vx

typeset view_mode=0
typeset send_mode=0
typeset force_mode=0
typeset src_machine=""
typeset user=zhaoyong.zzy
while getopts vsfm: ch; do
  case $ch in
    v) view_mode=1;;
    s) send_mode=1;;
    f) force_mode=1;;
    m) src_machine=$OPTARG;;
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
	typeset remote_file="/home/${user}/docs/${file##*/}"
	if ssh ${user}@$ip "test -f ${remote_file}"; then
		if [[ ${force_mode} -eq 1 ]]; then
			echo "Warning: ${file##*/} already exists on MYVM, overwriting (forced by -f)"
		else
			echo "Error: ${file##*/} already exists on MYVM (${remote_file})"
			echo "Please rename your file or use -f to force overwrite."
			exit 1
		fi
	fi
	scp $file ${user}@$ip:~/docs/
	fullpath=${remote_file}

	# Register to md_index.md on MYVM
	typeset md_title=$(grep -m1 '^# ' "$file" | sed 's/^# //')
	[[ -z "$md_title" ]] && md_title="${file##*/}"
	typeset preview_url="http://${ip}:38080/myhome/git/bashttpd/md_viewer.html?file=/os_root${fullpath}"
	typeset raw_url="http://${ip}:38080/os_root${fullpath}"
	typeset ts=$(date '+%Y%m%d_%H%M%S')
	typeset src_ip=${src_machine:-$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')}
	typeset src_dir=$(pwd)
	typeset git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
	typeset new_row="| [${md_title}](${preview_url}) | [原始md文件](${raw_url}) | ${ts} | ${src_ip} | ${src_dir} | ${git_branch} |"

	typeset index_file='~/docs/md_index.md'
	typeset header='| 标题 | 原始文件 | 创建时间 | 来源机器 | 来源目录 | Git分支 |'
	typeset separator='|------|----------|----------|----------|----------|---------|'

	ssh ${user}@$ip "
		if [[ ! -f ${index_file} ]]; then
			echo '${header}' > ${index_file}
			echo '${separator}' >> ${index_file}
		fi
		sed -i '2a\\${new_row}' ${index_file}
	"
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
