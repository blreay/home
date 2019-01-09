#!/bin/bash

while true; do
date | tee -a log
echo "=========================" | tee -a log
curl 'https://gmp.oracle.com/captcha/files/airespace_pwd_apac.txt' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Cookie: BIGipServergmp_oracle_com_http=324932752.20480.0000; s_nr=1454581792067; s_cc=true; s_sq=oracledocs%3D%2526pid%253Ddocs%25253Aen-us%25253A%25252Fcd%25252Fe37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Fdocs.oracle.com%25252Fcd%25252FE37115_01%25252Fdev.1112%25252Fe27134%25252Fappendixcurl.htm%252523BABEJCBF%2526ot%253DA; ORASSO_AUTH_HINT=v1.0~20160205183356; ORA_UCM_INFO=3~B10F1856A28EB24AE040548C2D7068AF~Zhaoyong~Zhang~zhaoyong.zhang@oracle.com; OHS-gmp.oracle.com-80=7B61B8750441602773F21DA9560947F699217F0BC90A6653626CAC5DB1E5283C0200225A75C42F958D9DE6CA6B658DF3A2D45B2B9DD63DC2D5BCB2B4B35CD7D9E82ACB7A8B4B14DC0721834F6D7C3184C98160E3B666509769BED50335C22C2C04BE280273055A13EB18349093B427268170334941C0ACA8590AB164CA8AC2D7B625270AA000483C1C819A2A8D343A7928766179D04078BFCEBA79729ABF5DFEE8646A7422DCC29C250D919B25C14CB69BB1233589F137E0CE932125318730B161854A2984A3E6B1D53240DAECEC2CF28DDB8A23548B091D323034AA433A07F6FCC8107BFA808004013B5C3549B1DD3D091EA7DD87F3FCBC~' -H 'Connection: keep-alive' --compressed -v | tee -a log

echo "===========begin to sleep at $(date) ==============" | tee -a log
sleep $((47*60))
done
