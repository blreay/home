#!/bin/bash

#this script is used to count every value's count
#  netstat -an | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'

awk '{++S[$NF]} END {for(a in S) print a, S[a]}'

