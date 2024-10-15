#!/bin/bash

set -e

git clone https://github.com/rvoicilas/inotify-tools.git
pushd inotify-tools
./autogen.sh && ./configure && make && sudo make install
