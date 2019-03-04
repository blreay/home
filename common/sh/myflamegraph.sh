#!/bin/bash

GRAPH_HOME=$PWD:FlameGraph
export PATH=$PATH:${GRAPH_HOME}

if [[ ! -d FlameGraph ]]; then
	git clone https://github.com/brendangregg/FlameGraph.git
fi

typeset -A aryfile=(
[svgfile]=perf.svg
[datafile]=perf.data
[unfoldfile]=perf.data.unfold
[foldedfile]=perf.data.folded
)

echo ${aryfile[*]}
set -vx
/bin/rm -f ${aryfile[*]}
perf record -F 299 -g $@
perf script -i ${aryfile[datafile]} &> ${aryfile[unfoldfile]} && \
stackcollapse-perf.pl ${aryfile[unfoldfile]} &> ${aryfile[foldedfile]} && \
flamegraph.pl ${aryfile[foldedfile]} > ${aryfile[svgfile]} && \
echo "OK"
