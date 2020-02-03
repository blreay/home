#!/bin/bash
source $SH/mycommon.sh

## this is the UT test for API or alias in my framework
## one function can be specified to test

funclist=(
BCS_CHK_ACT_RC0
)

function runcase {
	cmd="$1"
	act="$2"
	${cmd} >/dev/null 2>&1; BCS_CHK_ACT_RC0 "${act}" 2>&1
}

function my_test_BCS_CHK_ACT_RC0 {
echo "--------- cmd OK, 3 -----------------------"
ret=$(runcase "pwd" "pwd &&& echo ng ||| echo ok !!! echo all")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd &&& echo ng !!! echo all||| echo ok ");
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd ||| echo ok !!! echo all&&& echo ng ")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd ||| echo ok &&& echo ng !!! echo all")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd !!! echo all&&& echo ng ||| echo ok ")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd !!! echo all||| echo ok &&& echo ng ")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

echo "--------- cmd OK, 2 -----------------------"
ret=$(runcase "pwd" "pwd &&& echo ng ||| echo ok")
[[ $? -eq 0 && $ret == "ok" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd ||| echo ok&&& echo ng ")
[[ $? -eq 0 && $ret == "ok" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd !!! echo all ||| echo ok")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"

ret=$(runcase "pwd" "pwd ||| echo ok !!! echo all ")
[[ $? -eq 0 && $(echo ${ret}) == "ok all" ]] && echo "ok" || echo "ng ${ret}"


echo "--------- cmd OK, 1 -----------------------"
ret=$(runcase "pwd" "pwd ||| echo ok")
[[ $? -eq 0 && $ret == "ok" ]] && echo "ok" || echo "ng ${ret}"
ret=$(runcase "pwd" "pwd &&& echo ng")
[[ $? -eq 0 && $ret == "" ]] && echo "ok" || echo "ng ${ret}"
ret=$(runcase "pwd" "pwd !!! echo all")
[[ $? -eq 0 && $ret == "all" ]] && echo "ok" || echo "ng ${ret}"

echo "--------- cmd OK, 0 -----------------------"
ret=$(runcase "pwd" "pwd")
[[ $? -eq 0 && $ret == "" ]] && echo "ok" || echo "ng ${ret}"

echo "--------- cmd NG, 3 -----------------------"
ret=$(runcase "pwd0000" "pwd &&& echo ng ||| echo ok !!! echo all")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd &&& echo ng !!! echo all||| echo ok ");
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd ||| echo ok !!! echo all&&& echo ng ")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd ||| echo ok &&& echo ng !!! echo all")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd !!! echo all&&& echo ng ||| echo ok ")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd !!! echo all||| echo ok &&& echo ng ")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

echo "--------- cmd NG, 2 -----------------------"
ret=$(runcase "pwd0000" "pwd &&& echo ng ||| echo ok")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd ||| echo ok&&& echo ng ")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng\ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd !!! echo all ||| echo ok")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ all\ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

ret=$(runcase "pwd0000" "pwd ||| echo ok !!! echo all ")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ all\ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"


echo "--------- cmd NG, 1 -----------------------"
ret=$(runcase "pwd0000" "pwd ||| echo ok")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"
ret=$(runcase "pwd0000" "pwd &&& echo ng")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ ng.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"
ret=$(runcase "pwd0000" "pwd !!! echo all")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ all.*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

echo "--------- cmd NG, 0 -----------------------"
ret=$(runcase "pwd0000" "pwd")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"

echo "--------- cmd NG, alias -----------------------"
AA=123; BB=456
alias aaa='echo ${AA} ${BB}'
ret=$(runcase "pwd" "pwd &&& aaa ||| aaa !!! aaa")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"
}

function my_entry {
	allfunc="${1:-${funclist[*]}}"
	for func in ${allfunc}; do
		echo "---- TEST ${func} ---- BEGIN ----" 
		my_test_${func}
		echo "---- TEST ${func} ---- END ----" 
	done
}

main "$@"
