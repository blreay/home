#!/bin/bash

#添加docker-ce的repo：
sudo wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

#docker-ce.repo中添加centos-extras源:
vim /etc/yum.repos.d/docker-ce.repo
#在文档最上面添加源
[centos-extras]
name=Centos extras - $basearch
enabled=1
gpgcheck=0
baseurl=http://mirror.centos.org/centos/7/extras/x86_64

#安装docker-ce
sudo yum -y install docker-ce

#准备SNAT规则
systemctl disable --now nonf_conntrack
/usr/sbin/sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -j MASQUERADE
iptables-save
systemctl start docker
