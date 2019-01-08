#!/bin/bash

seed=${1:-"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="}
len=${#seed}
i=0
while [[ i -lt ${#seed} ]]; do
	b[$i]=-1
	a[$i]=${seed:$i:1}	
	#echo ${a[$i]}
	(( i = i + 1 ))
done

i=0
while [[ i -lt ${#seed} ]]; do
	#printf "%s" ${b[$i]}
	(( i = i + 1 ))
done

for i in $(seq $(($len-1))); do
	#rand=$(date +'%N')
	#rand2=$(date +'%N')
	rand=$RANDOM
	(( rand = rand % len ))
	rand2=$RANDOM
	(( rand2 = rand2 % len ))
	m=$rand
	n=$rand2
	#n=$i
	#(( n= len % m ))
	echo "rand=$rand m=$m n=$n "
	tmp=${a[$m]}
	a[$m]=${a[$n]}
	a[$n]=$tmp
done

i=0
while [[ i -lt ${#seed} ]]; do
	printf "%s" ${a[$i]}
	(( i = i + 1 ))
done
echo
