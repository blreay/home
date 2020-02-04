#!/bin/bash

yum install -y passwd openssl openssh-server

## generate mandatory files
/usr/sbin/sshd-keygen -A

sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

## startup
#/usr/sbin/sshd

echo $?
