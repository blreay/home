#!/bin/bash

### export GIT_SSH=<THIS FILE>

#echo $@ > /tmp/zzy
#ssh -i /u01/app/oracle/tools/home/oracle/home/common/sshkey/zzy01_rsa_private $@
ssh  -o "StrictHostKeyChecking=no" -i ${NFS}/common/sshkey/zzy01_rsa_private $@
