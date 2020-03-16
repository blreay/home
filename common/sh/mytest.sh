#!/bin/bash
source $SH/mycommon.sh

## this is the UT test for API or alias in my framework
## one function can be specified to test

funclist=(
BCS_CHK_ACT_RC0
BCS_ASSERT
BCS_RUN_AND_CHK
)

function runcase {
	cmd="$1"
	act="$2"
	${cmd} >/dev/null 2>&1; BCS_CHK_ACT_RC0 "${act}" 2>&1
}
function run_and_assert {
	cmd="$1"
	act="$2"
	BCS_ASSERT "${cmd} ${act}"
    echo "000"
}
function run_and_chk {
	cmd="$1"
	act="$2"
	BCS_RUN_AND_CHK "${cmd} ${act}"
}

function my_test_BCS_ASSERT {
    CMDOK="ls / > /dev/null"
    CMDNG="rm /aaa/ccc 2>/dev/null"
    echo "------ CMD OK ------"
    ret=$(run_and_assert "${CMDOK}")
    [[ $? -eq 0 && $(echo ${ret}) == "000" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDOK}" "@@@ failed to run")
    [[ $? -eq 0 && $(echo ${ret}) == "000" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999")
    [[ $? -eq 0 && $(echo ${ret}) == "000" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888")
    [[ $? -eq 0 && $(echo ${ret}) == "888 000" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888")
    [[ $? -eq 0 && $(echo ${ret}) == "888 000" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777")
    [[ $? -eq 0 && $(echo ${ret}) == "888 777 000" ]] && echo "ok" || echo "ng ${ret}"

    echo "------ CMD NG ------"
    ret=$(run_and_assert "$CMDNG" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "$CMDNG" "@@@ AAA BBB" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB &&& echo 999" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*888.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*777.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
}
function my_test_BCS_RUN_AND_CHK {
    CMDOK="ls / > /dev/null"
    CMDNG="rm /aaa/ccc 2>/dev/null"
    echo "------ CMD OK ------"
    ret=$(run_and_chk "${CMDOK}")
    [[ $? -eq 0 && $(echo ${ret}) == "" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDOK}" "@@@ failed to run")
    [[ $? -eq 0 && $(echo ${ret}) == "" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999")
    [[ $? -eq 0 && $(echo ${ret}) == "" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888")
    [[ $? -eq 0 && $(echo ${ret}) == "888" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888")
    [[ $? -eq 0 && $(echo ${ret}) == "888" ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777")
    [[ $? -eq 0 && $(echo ${ret}) == "888 777" ]] && echo "ok" || echo "ng ${ret}"

    echo "------ CMD NG ------"
    ret=$(run_and_chk "$CMDNG" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "$CMDNG" "@@@ AAA BBB" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB &&& echo 999" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*888.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
    ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777" 2>&1)
    [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*777.*AAA\ BBB.*RET=1$ ]] && echo "ok" || echo "ng ${ret}"
}
function my_entry_BCS_ASSERT {
    BCS_ASSERT "rm /aaa/bbb @@@ faild to delete file /aaa/bbb &&& echo 999 ||| echo 888 !!! echo 777"
    BCS_ASSERT "ls /etc @@@ faild to delete file /aaa/bbb ||| echo 666"
    BCS_ASSERT "rm /aaa/bbb @@@ faild to delete file /aaa/bbb ||| echo 777"
    BCS_ASSERT "rm /aaa/bbb @@@ faild to delete file /aaa/bbb !!! echo 888"
    BCS_ASSERT "rm /aaa/bbb @@@ faild to delete file /aaa/bbb &&& echo 999"
    BCS_ASSERT "rm /aaa/bbb @@@ faild to delete file /aaa/bbb"
    BCS_ASSERT "rm /aaa/bbb"
    BCS_ASSERT "[[ $a -eq 9 ]]"
    BCS_ASSERT "[[ $a -eq 9 ]] @@@ a is incorrect"
    echo "what"
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
ret=$(runcase "pwd000" "pwd &&& aaa ||| aaa !!! aaa")
[[ $? -ne 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ .*pwd.*RET=127 ]] && echo "ok" || echo "ng [${ret}]"
ret=$(runcase "pwd" "pwd &&& aaa ||| aaa !!! aaa")
[[ $? -eq 0 && "$(echo "${ret}" | tr '\n' ' ')" =~ 123\ 456\ 123\ 456 ]] && echo "ok" || echo "ng [${ret}]"
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
