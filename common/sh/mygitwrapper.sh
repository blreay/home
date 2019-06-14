#!/bin/bash

### export GIT_SSH=<THIS FILE>

#echo $@ > /tmp/zzy
#ssh -i /u01/app/oracle/tools/home/oracle/home/common/sshkey/zzy01_rsa_private $@
#SSH_PORT is used to ssh tunnel
ssh ${SSH_PORT:+-p ${SSH_PORT}} -o "StrictHostKeyChecking=no" -i ${NFS}/common/sshkey/zzy01_rsa_private $@
