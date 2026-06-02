#!/bin/bash

echo $(printf "%0.1s" "="{1..10}) ifconifg $(printf "%0.1s" "="{1..10})
ifconfig | egrep "inet " | awk '{print $2}'
echo

CMD="curl cip.cc"
echo $(printf "%0.1s" "="{1..10}) $CMD $(printf "%0.1s" "="{1..10})
eval ${CMD}
echo

CMD="curl ip.me"
echo $(printf "%0.1s" "="{1..10}) $CMD $(printf "%0.1s" "="{1..10})
eval ${CMD}
echo

CMD="curl ipinfo.io"
echo $(printf "%0.1s" "="{1..10}) $CMD $(printf "%0.1s" "="{1..10})
eval ${CMD}
echo

CMD="curl icanhazip.com"
echo $(printf "%0.1s" "="{1..10}) $CMD $(printf "%0.1s" "="{1..10})
eval ${CMD}
echo

CMD="curl -s --connect-timeout 300 \"http://ip-api.com/json/$(curl -s ip.me)?fields=country,regionName,city,isp,org\""
echo $(printf "%0.1s" "="{1..10}) $CMD $(printf "%0.1s" "="{1..10})
eval "${CMD}"
echo

