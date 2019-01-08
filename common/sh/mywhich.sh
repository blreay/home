utiname=$1
if [[ -z $utiname ]]; then
	exit 1
fi

utipath=$(which $utiname)
echo $utipath
utidir=${utipath%/*}
#echo $utidir
. showfullpath.sh $utidir

