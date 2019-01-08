#!/bin/bash

awk '{ total += $NF; count++ } END { print total/count }' $1
