#!/bin/bash

typeset ctnid=${1}
typeset urlroot="http://www.dybcotton.com"

[[ -z $ctnid ]] && echo "usage: $0 <cotton_id>" && exit 1

curl "${urlroot}$(curl "$urlroot/search/express" -H 'Cookie: PHPSESSID=sjfh2mddm99skcl0pf53prbcs7; Hm_lvt_0e56d9d524f3b09c85e6f4ff29728217=1482117643; Hm_lpvt_0e56d9d524f3b09c85e6f4ff29728217=1482202274' -H 'Origin: http://www.dybcotton.com' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4,ja;q=0.2,de;q=0.2,zh-TW;q=0.2' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://www.dybcotton.com/' -H 'Connection: keep-alive' --data "search=$ctnid" --compressed 2>/dev/null |egrep "href.*$ctnid" | sed 's/.\{1,\}href=\"\([^\"]\{1,\}\).\{1,\}$/\1/')" > out.html 

