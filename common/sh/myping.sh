###########################################
prefix=$1
begin=$2;
end=$3;
while [[ $begin -lt $end ]]; do 
	ping $prefix$begin -c 1 -W 1 1>/dev/null 2>/dev/null; 
	[[ $? -eq 0 ]] && echo $prefix$begin; 
	(( begin=begin+1 )); 
done
