#!/bin/bash

DIR=`pwd`
update=1
change=0
unset OPTIND
while getopts "d:uc" opt; do
  case $opt in
    d) DIR=$OPTARG ;;
    u) update=1 ;;
    c) change=1 ;;
    ?) echo "invaild option!"; exit 1
  esac
done
shift $((OPTIND - 1))

cd ${DIR}

if [ 1 -eq ${change} ]; then
  echo "change project cscope database!"
  res=$(find ${DIR} -name cscope.out)
  if [ "x"${res} = "x" ]; then
    echo "Not found cscope database, generate cscope database!"
    find ${DIR} -name "*.h" -o -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.hh" -o -name "*.hpp" > cscope.files
    cscope -bkq -i cscope.files 
    ctags -R --c++-kinds=+p --fields=+iaS --extra=+q *
    export CSCOPE_DB=${DIR}/cscope.out
  else
    echo "Found cscope database:${res}, just change CSCOPE_DB env!"
    export CSCOPE_DB=${res}
  fi
elif [ 1 -eq ${update} ]; then
  echo "udpate project cscope database!"
  find ${DIR} -name "*.h" -o -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.hh" -o -name "*.hpp" > cscope.files
  cscope -bkq -i cscope.files
  ctags -R --c++-kinds=+p --fields=+iaS --extra=+q *
  export CSCOPE_DB=${DIR}/cscope.out
fi

echo CSCOPE_DB_PATH=${CSCOPE_DB}
