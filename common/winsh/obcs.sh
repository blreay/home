#/bin/bash

obj=${1:-obcs}

cd /cygdrive/c/zzy/software/program/VSCode-win32-x64-1.18.1;
case $obj in
obcs) export GOPATH='D:\oracle\share\bcs\go';;
bcs)  export GOPATH='D:\oracle\share\bcs\goca.v1.0.2';;
esac

./Code.exe
