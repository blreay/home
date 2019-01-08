#!/bin/ksh

function process_one_file {
	typeset fn=$1
	if [[ -z $fn ]]; then
		return 1
	fi
	dos2unix $fn 2>/dev/null
	indent -npro -kr -i4 -ts4 -nsob -l180 -ss -ncs -cp1 -br -nut -nbc ${fn} -o ${fn}.new
	diff ${fn} ${fn}.new > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		mv ${fn}.new ${fn}
		echo "$fn"
	fi
	rm -f ${fn}.new
	return 0
}

##############################
## main
##############################
if [[ -n $1 ]]; then
	## process one file ##
	process_one_file $1
else 
	## process all files ##
	while read line; do
		if [[ -z $line ]];then 
			continue;
		fi
		fn=$line
		process_one_file $fn
	done <<-EOF
	`find . -name "*.c" | egrep -v "(art/jcl|lib/batchrt/SOURCE)"`
	`find . -name "*.h" | egrep -v "(art/jcl|lib/batchrt/SOURCE)"`
EOF
fi
