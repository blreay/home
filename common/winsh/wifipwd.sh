#!/bin/bash

############################################
typeset txturl="$SSO_WIFI_PWD_URL"
typeset myusername="$SSO_NAME"
typeset mypwd="$SSO_PWD"
typeset cookiefn=/tmp/mycookie
typeset curl_timeout=20
typeset useragent="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36"
typeset curlcmd="curl -v -L -A \"${useragent}\"  --retry 2 --retry-delay 1 --retry-max-time $curl_timeout --max-time $curl_timeout --insecure -c $cookiefn -b $cookiefn "

########################################## 
function clean_tmp {
	rm -f $cookiefn $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $tmp6 $namef $valuef
}

function getpwd {
	typeset outfile=$1
	typeset tmp1=/tmp/curl.1
	typeset tmp2=/tmp/curl.2
	typeset tmp3=/tmp/curl.3
	typeset tmp4=/tmp/curl.4
	typeset tmp5=/tmp/curl.5
	typeset tmp6=/tmp/curl.6
	typeset namef=/tmp/curl.name
	typeset valuef=/tmp/curl.value
	clean_tmp 

	##launch URL
	eval ${curlcmd} $txturl -o $tmp1 
	cat $tmp1 | sed 's/</\n</g' > $tmp2 
	cat $tmp2 | awk -F "\"" '/input.*name=/ {print $4"="$6 }' | tr "\n" "&" > $tmp3 
	formdata1=$(cat $tmp3| sed 's/&$//g')

	##submit auto submit page, return the real login page
	typeset form_action=$(cat $tmp2| grep "action="| awk -F "\"" '{print $2}')
	typeset host=$(echo $form_action|awk '{match($0,/.+:\/\/[^\/]+/);s=substr($0,RSTART,RLENGTH);print s}')
	eval $curlcmd -d \"${formdata1}\" $form_action -o $tmp4 

	## analyze the form field in the real login page
	cat $tmp4 |grep "name="| egrep -v "(<meta|<form)" | awk '{match($0,/name="[^"]*"/); s = substr($0,RSTART, RLENGTH); gsub(/["]/, "", s); print s}' > $namef
	cat $tmp4 |grep "value="| egrep -v "(<meta|<form)" | awk '{match($0,/value="[^"]*"/); s = substr($0,RSTART, RLENGTH); gsub(/["]/, "", s); print s}' > $valuef 
	typeset formdata3=""
	for i in $(seq $(cat $namef | wc -l)); do
		typeset n1=$(cat $namef | awk -F "=" 'NR=='"$i"'{print $2}')
		typeset n2=$(cat $valuef | awk -F "=" 'NR=='"$i"'{print $2}')
		[[ $n1 == "ssousername" ]] && n2="$myusername"
		[[ $n1 == "password" ]] && n2="$mypwd"
		n22="$(php -r "echo rawurlencode('$n2');")"
		formdata3="${formdata3}&${n1}=${n22}"
	done 

	## submit the login form 
	typeset form_action2=$(cat $tmp4| grep "action="| awk -F "\"" '{print $4}')
	typeset url="${host}${form_action2}"
	eval $curlcmd --data-binary \"${formdata3#&}\" $url -o $tmp6

	cat $tmp6 > $outfile

	## clear all tmp file
	test X"$MYDBG" != X"yes" && clean_tmp
}

#############################################
while true; do
	getpwd "$HOME/wifiinfo.txt" 2>/dev/null
	[[ $1 -eq 0 ]] && break
	sleep ${1:-$((3 * 60 + $RANDOM % 200))} 
done 
