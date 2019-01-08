#!/bin/bash

typeset txturl="$SSO_WIFI_PWD_URL"
typeset myusername="$SSO_NAME"
typeset mypwd="$SSO_PWD"
typeset cookiefn=/tmp/mycookie
typeset curl_timeout=20
typeset useragent="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36"
#typeset useragent="Mozilla/5.0 aaa"

## with detailed verbose information
#typeset curlcmd="curl -v -L -A \"${useragent}\"  --retry 2 --retry-delay 1 --retry-max-time $curl_timeout --max-time $curl_timeout --insecure -c $cookiefn -b $cookiefn "
typeset curlcmd="curl -L -A \"${useragent}\"  --retry 2 --retry-delay 1 --retry-max-time $curl_timeout --max-time $curl_timeout --insecure -c $cookiefn -b $cookiefn "
#[[ "${MYDBG}" == "yes" ]] && curlcmd="${curlcmd} -v"

########################################## 
function show_usage {
	showerr "Usage: ${g_appname##*/} [-d delimiter] [-s new delimiter] string"
    showerr "        -d : specify the delimiter" 
    showerr "        -s : specify the new delimiter" 
}

function showdbg {
	if [[ $MYDBG = "yes" ]]; then
		showerr ${@:+"$@"}
	fi
} 
function showerr {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}" >&2
}
function showmsg {
	echo "$(date +'%Y%m%d_%H%M%S') ${@:+"$@"}"
}

function clean_tmp {
	rm -f $cookiefn $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $tmp6 $namef $valuef
}
#############################
#set -vx
typeset tmp1=/tmp/curl.1
typeset tmp2=/tmp/curl.2
typeset tmp3=/tmp/curl.3
typeset tmp4=/tmp/curl.4
typeset tmp5=/tmp/curl.5
typeset tmp6=/tmp/curl.6
typeset namef=/tmp/curl.name
typeset valuef=/tmp/curl.value
clean_tmp

showmsg "fetch wifi pwd from web server"

## First page, return the auto submit page
eval ${curlcmd} $txturl -o $tmp1

############################
cat $tmp1 | sed 's/</\n</g' > $tmp2 
cat $tmp2 | awk -F "\"" '/input.*name=/ {print $4"="$6 }' | tr "\n" "&" > $tmp3 
formdata1=$(cat $tmp3| sed 's/&$//g')
#echo "formdata1=[$formdata1]"

##submit auto submit page, return the real login page
typeset form_action=$(cat $tmp2| grep "action="| awk -F "\"" '{print $2}')
echo "form_action=$form_action" 
typeset host=$(echo $form_action|awk '{match($0,/.+:\/\/[^\/]+/);s=substr($0,RSTART,RLENGTH);print s}')
echo "host=$host" 
eval $curlcmd -d \"${formdata1}\" $form_action -o $tmp4 

## analyze the form field in the real login page, and fillin the mandatory value, such as username and password
cat $tmp4 |grep "name="| egrep -v "(<meta|<form)" | awk '{match($0,/name="[^"]*"/); s = substr($0,RSTART, RLENGTH); gsub(/["]/, "", s); print s}' > $namef
cat $tmp4 |grep "value="| egrep -v "(<meta|<form)" | awk '{match($0,/value="[^"]*"/); s = substr($0,RSTART, RLENGTH); gsub(/["]/, "", s); print s}' > $valuef 
typeset formdata3=""
for i in $(seq $(cat $namef | wc -l)); do
	typeset n1=$(cat $namef | awk -F "=" 'NR=='"$i"'{print $2}')
	typeset n2=$(cat $valuef | awk -F "=" 'NR=='"$i"'{print $2}')
	[[ $n1 == "ssousername" ]] && n2="$myusername"
	[[ $n1 == "password" ]] && n2="$mypwd"
	n22="$(php -r "echo rawurlencode('$n2');")"
	showdbg "n2=$n2  n22=$n22  n1=$n1" 
	formdata3="${formdata3}&${n1}=${n22}"
done 
echo "formdata3=$formdata3"

## submit the login form 
typeset form_action2=$(cat $tmp4| grep "action="| awk -F "\"" '{print $4}')
echo "form_action2=$form_action2" 
###!!!!! important: following is the full format, maybe will be used in the future !!!!
##******************************************
#eval $curlcmd --data-binary \"${formdata3#&}\" -H \'Origin: https://login.oracle.com\' -H \'Accept-Encoding: gzip, deflate\' -H \'Accept-Language: en-US,en\;q=0.8,zh-CN\;q=0.6,zh\;q=0.4\' -H \'Upgrade-Insecure-Requests: 1\' -H \'User-Agent: Mozilla/5.0 \(Windows NT 6.1\; WOW64\) AppleWebKit/537.36 \(KHTML, like Gecko\) Chrome/48.0.2564.97 Safari/537.36\' -H \'Content-Type: application/x-www-form-urlencoded\' -H \'Accept: text/html,application/xhtml+xml,application/xml\;q=0.9,image/webp,*/*\;q=0.8\' -H \'Cache-Control: max-age=0\' -H \'Referer: https://login.oracle.com/mysso/signon.jsp\' -H \'Connection: keep-alive\' https://login.oracle.com/oam/server/sso/auth_cred_submit -o 6
##******************************************
#eval $curlcmd --data-binary \"${formdata3#&}\"  https://login.oracle.com/oam/server/sso/auth_cred_submit -o 6
typeset url="${host}${form_action2}"
echo "url=$url"
eval $curlcmd --data-binary \"${formdata3#&}\" $url -o $tmp6

cat $tmp6

## clear all tmp file
test X"$MYDBG" != X"yes" && clean_tmp

exit 0

