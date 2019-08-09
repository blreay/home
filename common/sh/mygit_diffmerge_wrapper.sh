#!/bin/bash

# this is the wrapper for git to use diffmerge as "diff" or "merge" tool

# diff is called by git with 7 parameters:
# path old-file old-hex old-mode new-file new-hex new-mode

# passing the following parameters to mergetool:
# local base remote merge_result

echo "parameters: $@"

act=$1
shift 1

case $act in
diff)
	"diffmerge" "$1" "$2"
	;;
merge)
	"diffmerge" "$1" "$2" "$3" --result="$4" --title1="Mine" --title2="Merge" --title3="Theirs"
	;;
*) echo "no support act: $act"; exit 1;;
esac
