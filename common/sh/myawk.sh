#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mycommon.sh"
typeset g_mandatory_utilities=(awk sed jq)

function my_entry {
    typeset host="${1:-$MYVM01}"
    typeset interval="${2:-$((60*30))}"
    #awk '{count[$0]++} END {for (line in count) {printf("%s\t%s\n",count[line], line)}}' | sort -Vr
    awk '{count[$0]++} END {for (line in count) {printf("%s\t%s\n",count[line], line)}}'
}

main ${@}
