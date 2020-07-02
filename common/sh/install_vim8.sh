#!/bin/bash

cat - <<EOF
rpm -Uvh http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm
rpm --import http://mirror.ghettoforge.org/distributions/gf/RPM-GPG-KEY-gf.el7

## don't remove them, because sudo will be removed also, just upgrade them is ok
#yum -y remove vim-minimal vim-common vim-enhanced sudo
#yum -y --enablerepo=gf-plus install vim-enhanced sudo

yum -y --enablerepo=gf-plus install vim-enhanced vim-minimal
EOF

## in order to support spacevim
sudo wget -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/elyezer/vim-latest/repo/epel-7/elyezer-vim-latest-epel-7.repo
sudo yum install -y vim

## install spacevim
# https://spacevim.org/quick-start-guide/
cd ~
curl -sLf https://spacevim.org/install.sh | bash

echo "make vimproc"
cd ~/.SpaceVim/bundle/vimproc.vim && mkdir -p lib && make
