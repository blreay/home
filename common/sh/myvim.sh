#!/bin/bash

###########################################
mt_obj=$1
if [[ -z $mt_obj ]]; then
	echo "usage: ${0##*/} <object>"
	exit 1
fi
fullpath=$(which $mt_obj)
if [[ -n $fullpath ]]; then
	vim $fullpath
fi

echo $fullpath
