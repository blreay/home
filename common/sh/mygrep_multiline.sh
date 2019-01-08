#!/bin/sh
 
search=$1
file=$2
#shift

#for file; do
sed '
/'"$search"'/b 
N 
h
s/.*\n//
/'"$search"'/b
g
s/ *\n/ /
/'"$search"'/{
g
b
}
g
D' $file
#done
