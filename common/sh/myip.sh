#!/bin/bash

ifconfig | egrep "inet " | awk '{print $2}'
