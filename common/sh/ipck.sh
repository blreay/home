#!/bin/sh

# 本脚本删除当前用户所使用的IPC资源

ipc_kill()
{
	for i in \
	`ipcs -$1 | grep $Usr \
			| awk '{
				if(length($1) > 1)
					print substr($1, 2, length($1) - 1)
				else
					print $2;
			}'`
	do
		ipcrm -$1 $i
	done
}
	

Usr=`whoami`

ipc_kill q
ipc_kill s
ipc_kill m

ipcs -o | grep $Usr
