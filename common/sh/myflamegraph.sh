#!/bin/bash

GRAPH_HOME=$PWD:FlameGraph
export PATH=$PATH:${GRAPH_HOME}

if [[ ! -d FlameGraph ]]; then
	git clone https://github.com/brendangregg/FlameGraph.git
fi

perf record -F 99 -g $@ && \
perf script -i perf.data &> perf.unfold && \
stackcollapse-perf.pl perf.unfold &> perf.folded && \
flamegraph.pl perf.folded > perf.svg
