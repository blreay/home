#!/bin/bash

ifconfig | egrep "inet " | awk '{print $2}'

curl cip.cc
