#!/bin/bash

cat - <<EOF
rpm -Uvh http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm
rpm --import http://mirror.ghettoforge.org/distributions/gf/RPM-GPG-KEY-gf.el7

## don't remove them, because sudo will be removed also, just upgrade them is ok
#yum -y remove vim-minimal vim-common vim-enhanced sudo
#yum -y --enablerepo=gf-plus install vim-enhanced sudo

yum -y --enablerepo=gf-plus install vim-enhanced vim-minimal
EOF

function build_from_src {
  ## on CentOS Linux release 7.6.1810 (Core)
  yum install -y ncurses-devel.x86_64

  url=https://github.com/vim/vim/archive/v8.2.1153.zip
  zip=${url##*/}
  dir=$(unzip -l ${zip} | grep CONTRIBUTING.md | awk '{print $NF}' | cut -d '/' -f 1)
  wget ${url}
  unzip ${zip}
  cd ${dir}
  SRCDIR= ./configure --with-features=huge \
            --enable-multibyte \
            --enable-python3interp=yes \
            --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=/usr/local/vim
  make -j16
  ##### YCM #############
  cd ./vimfiles/repos/github.com/Valloric/YouCompleteMe
  git submodule update --init --recursive
  ./install.py
}

## in order to support spacevim
sudo wget -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/elyezer/vim-latest/repo/epel-7/elyezer-vim-latest-epel-7.repo
sudo yum install -y vim

## install spacevim
# https://spacevim.org/quick-start-guide/
cd ~
curl -sLf https://spacevim.org/install.sh | bash

echo "make vimproc"
cd ~/.SpaceVim/bundle/vimproc.vim && mkdir -p lib && make
