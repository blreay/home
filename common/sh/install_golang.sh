#!/bin/bash

wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz

#Do not untar the archive into an existing /usr/local/go tree. This is known to produce broken Go installations.
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz

#need to add following statement to your .bashrc or /etc/profile
export PATH=$PATH:/usr/local/go/bin

go version

