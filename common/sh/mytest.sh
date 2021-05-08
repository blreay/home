#!/bin/bash
source $SH/mycommon.sh

## this is the UT test for API or alias in my framework
## one function can be specified to test
## how to run: ./mytest.sh  |egrep -v "(^ok|^----)"

funclist=(
  BCS_CHK_ACT_RC0
  BCS_ASSERT
  BCS_RUN_AND_CHK
  my_bcs_stack
  debug
)

function runcase {
  cmd="$1"
  act="$2"
  #set -o | grep verbose
  ${cmd} >/dev/null 2>&1; BCS_CHK_ACT_RC0 "${act}" 2>&1
}
function run_and_assert {
  typeset cmd="$1"
  typeset act="${2:-}"
  BCS_ASSERT "${cmd} ${act}"
  typeset ret=$?
  echo "000"
  return ${ret}
}
function run_and_chk {
  [[ ${BCS_IS_VERBOSE} -eq 1 ]] && set -vx
  cmd="${1}"
  act="${2:-}"
  BCS_RUN_AND_CHK "${cmd} ${act}"
}

function test_BCS_CHK_ACT_RC0_Level2 {
  typeset cmd="$1"
  typeset act="${2:-}"
  eval ${cmd}
  BCS_CHK_ACT_RC0 "in ${FUNCNAME[0]}, ERROR occured &&& echo ng_action_in_child ${FUNCNAME[0]} ||| echo ok_action_in_child ${FUNCNAME[0]} !!! echo all_action_in_child ${FUNCNAME[0]} $BASHPID"
}
function test_BCS_CHK_ACT_RC0_Level1 {
  typeset cmd="$1"
  typeset cmd2="${2:-pwd}"
  #ls / > /dev/null
  eval ${cmd}
  BCS_CHK_ACT_RC0 "failed &&& echo ng_action_in_parent ${FUNCNAME[0]} ||| test_BCS_CHK_ACT_RC0_Level2 \"${cmd2}\" !!! echo all_action_in_parent ${FUNCNAME[0]}"
}
function my_test_debug {
  typeset CMD=""
  #ls / > /dev/null
  #BCS_CHK_ACT_RC0 "failed &&& echo ng_action in ${FUNCNAME[0]} ||| test_BCS_CHK_ACT_RC0_Level2 \"ls /not_exist\" !!! echo all_action in ${FUNCNAME[0]}"
  #my_entry_BCS_ASSERT
}
function my_test_my_bcs_stack {
  typeset CMD=""
  typeset stack=""
  typeset DD=${g_bcs_stack_demiliter}
  my_bcs_stack_push stack 3
  ## use (BCS_RUN_AND_CHK XXX) to avoid current function return when error occured
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3\" ]]")
  [[ $? -eq 0 ]] && echo "ok" || echo "ng ${ret} stack=${stack})"
  my_bcs_stack_push stack 4
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4\" ]]")
  [[ $? -eq 0 ]] && echo "ok" || echo "ng ${ret} stack=${stack})"
  my_bcs_stack_push stack 9
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4${DD}9\" ]]")
  ret=$? && [[ ${ret} -eq 0 ]] && echo "ok" || echo "ng01 ${ret} stack=${stack})"

  my_bcs_stack_top stack AA
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4${DD}9\" ]]")
  ret=$? && [[ ${ret} -eq 0 && "${AA}" == "9" ]] && echo "ok" || echo "ng00 ${ret} stack=${stack})"

  my_bcs_stack_pop stack
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4\" ]]")
  ret=$? && [[ ${ret} -eq 0 ]] && echo "ok" || echo "ng02 ${ret} stack=${stack})"

  my_bcs_stack_pop stack AA
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3\" ]]")
  ret=$? && [[ ${ret} -eq 0 && "${AA}" == "4" ]] && echo "ok" || echo "ng02 ${ret} stack=${stack})"

  my_bcs_stack_top stack AA
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3\" ]]")
  ret=$? && [[ ${ret} -eq 0 && "${AA}" == "3" ]] && echo "ok" || echo "ng00 ${ret} stack=${stack})"

  echo "------ exception push ------"
  my_bcs_stack_push stack 4
  ret=$(my_bcs_stack_push 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  ret=$(my_bcs_stack_push stack_NOT_EXIST 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  ret=$(my_bcs_stack_push stack_NOT_EXIST 8 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ unbound\ variable ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4\" ]]")
  [[ $? -eq 0 ]] && echo "ok" || echo "ng ${ret} stack=$(eval echo \$${stack})"

  echo "------ exception pop ------"
  ret=$(my_bcs_stack_pop stack_NOT_EXIST 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ unbound\ variable ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  ret=$(my_bcs_stack_pop stack_NOT_EXIST AA 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ unbound\ variable ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"

  echo "------ exception top ------"
  ret=$(my_bcs_stack_top 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  ret=$(my_bcs_stack_top stack 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  ret=$(my_bcs_stack_top stack_NOT_EXIST AA 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ unbound\ variable ]] && echo "ok" || echo "ng001 ${ret} stack=${stack}"
  (BCS_RUN_AND_CHK "[[ \"${stack}\" == \"${DD}3${DD}4\" ]]")
  [[ $? -eq 0 ]] && echo "ok" || echo "ng ${ret} stack=$(eval echo \$${stack})"
}

function my_test_BCS_ASSERT {
  typeset CMD=""
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
  [[ $? -eq 0 && $(echo ${ret}) == "888 000" ]] && echo "ok" || echo "XXX ng01 ${ret}"
  ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888")
  [[ $? -eq 0 && $(echo ${ret}) == "888 000" ]] && echo "ok" || echo "XXX ng02 ${ret}"
  ret=$(run_and_assert "${CMDOK}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777")
  [[ $? -eq 0 && $(echo ${ret}) == "888 777 000" ]] && echo "ok" || echo "XXX ng03 ${ret}"
  ret=$(run_and_assert "[[ \"${CMDOK}\" != \"not_exist\" ]]")
  [[ $? -eq 0 && $(echo ${ret}) == "000" ]] && echo "ok 0001" || echo "ng ${ret}"

  echo "------ CMD NG ------"
  ret=$(run_and_assert "$CMDNG" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ERROR ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_assert "$CMDNG" "@@@ AAA BBB" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB &&& echo 999" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng01 ${ret}"
  ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*888.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_assert "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*777.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
}
function my_test_BCS_RUN_AND_CHK {
  typeset CMD=""
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
  [[ $? -ne 0 && $(echo ${ret}) =~ AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB &&& echo 999" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 !!! echo 888" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*888.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"
  ret=$(run_and_chk "${CMDNG}" "@@@ AAA BBB ${CMD} &&& echo 999 ||| echo 888 !!! echo 777" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ^999.*777.*AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng ${ret}"

  echo "------ CMD COND ------"
  a="NNN"
  ret=$(run_and_chk "[[ -n '$a' ]]" "@@@ AAA BBB" 2>&1)
  [[ $? -eq 0 && $(echo ${ret}) == "" ]] && echo "ok" || echo "ng01 ${ret}"

  a=
  ret=$(run_and_chk "[[ -n \"$a\" ]]" "@@@ AAA BBB" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ AAA\ BBB.*RET=1 ]] && echo "ok" || echo "ng02 ${ret}"
}
function my_entry_BCS_ASSERT {
  BCS_ASSERT "pwd@@@ faild to delete file /aaa/bbb &&& echo 999 ||| echo 888 !!! echo 777"
  AA=abc
  unset AA
  AA=abc
  BCS_ASSERT "[[ \"${AA}\" == \"abc\" ]] @@@ value of AA is $AA &&& echo 902 ||| echo 802 !!! echo 702"
  AA=1
  BCS_ASSERT "[[ ${AA} -eq 1 ]] @@@ value of AA is $AA &&& echo 900 ||| echo 800 !!! echo 700"
  AA=9
  BCS_ASSERT "[[ ${AA} -eq 1 ]] @@@ value of AA is $AA &&& echo 901 ||| echo 801 !!! echo 701"
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

  echo "--------- loop -----------------------"
  ret=$(test_BCS_CHK_ACT_RC0_Level1 "ls /not_exist" "ls /not_exist" 2>&1)
  [[ $? -ne 0 && $(echo ${ret}) =~ ng_action_in_parent.*all_action_in_parent ]] && echo ok 001 || echo "ng  ret=$ret"
  ret=$(test_BCS_CHK_ACT_RC0_Level1 "echo run_must_ok" "ls /not_exist" 2>&1)
  [[ $? -eq 0 && $(echo "${ret}") =~ ng_action_in_child.*all_action_in_child.*all_action_in_parent ]] && echo ok 002 || echo "ng  ret=$ret"
  ret=$(test_BCS_CHK_ACT_RC0_Level1 "echo run_must_ok" "pwd" 2>&1)
  [[ $? -eq 0 && $(echo "${ret}") =~ ok_action_in_child.*all_action_in_child.*all_action_in_parent ]] && echo ok 003 || echo "ng  ret=$ret"
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
