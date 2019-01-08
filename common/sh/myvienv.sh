#!/bin/ksh

longhostname=$(uname -n)
hostname=${longhostname%%.*}
filename=setenv.$hostname.current.sh
path=$(dirname $(which appdir.sh))/conf/$filename
echo $path
vim $path
