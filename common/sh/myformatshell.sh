#!/bin/bash

## Add {} for all the variables
file=$1
[[ -z "${file}" ]] && echo "shell script file is not specified" && exit 1

sed 's/\$\([a-zA-Z][a-zA-Z0-9_]\{0,\}\)/\${\1}/g' ${file}
