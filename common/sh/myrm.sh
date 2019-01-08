#/bin/pdksh

typeset movetarget=${DIR_TRASH:-/nfs/users/zhaozhan/gomihako}
typeset mt_srcfullpath=""
for i in ${@}; do
	#echo ${i}
	#if [[ "${i}" = @(aaa) ]]; then
	echo $i | egrep "^-" >/dev/null
	if [[ $? -eq 0 ]]; then
		continue
	fi
	newname=$movetarget/$(uname -n)_$(date '+%Y%m%d_%H%M%S')_${i##*/}
	newnamedcb=$newname.dcb
	msg=$(mv -f $i $newname 2>&1)
	if [[ $? -ne 0 ]]; then
		printf "XXXXX\t\t%s\t\t%s\n" "$i" "$msg"
	else
		printf "OK\t\t%s\t\t%s\n" "$i" "$newname"
		echo $i | egrep "^/" >/dev/null
		if [[ $? -eq 0 ]]; then
			#absolute path
			mt_srcfullpath=$i
		else
			#relative path
			mt_srcfullpath="$(pwd)/$i" 
		fi
		echo $mt_srcfullpath > $newnamedcb
	fi
done
