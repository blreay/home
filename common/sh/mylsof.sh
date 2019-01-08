utiname=$1
if [[ -z $utiname ]]; then
	exit 1
fi

eval lsof -p \$\(ps -ef|grep ${USER}|grep ${utiname}|awk '{print $2}'\)
