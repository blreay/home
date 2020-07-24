#!/bin/bash

cat - <<EOF
rpm -Uvh http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm
rpm --import http://mirror.ghettoforge.org/distributions/gf/RPM-GPG-KEY-gf.el7

## don't remove them, because sudo will be removed also, just upgrade them is ok
#yum -y remove vim-minimal vim-common vim-enhanced sudo
#yum -y --enablerepo=gf-plus install vim-enhanced sudo

yum -y --enablerepo=gf-plus install vim-enhanced vim-minimal
EOF

function build_vim_prepare {
  ## on CentOS Linux release 7.6.1810 (Core)
  set -vx
  sudo yum install -y ncurses-devel.x86_64
  sudo yum install -y python3 python3-devel

}

function build_from_src {
  set -vx
  url=https://github.com/vim/vim/archive/v8.2.1153.zip
  zip=${url##*/}
  dir=$(unzip -l ${zip} | grep CONTRIBUTING.md | awk '{print $NF}' | cut -d '/' -f 1)
  #wget ${url}
  unzip ${zip}
  cd ${dir}
  pwd
  SRCDIR= ./configure --with-features=huge \
    --enable-multibyte \
    --enable-python3interp=yes \
    --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu \
    --enable-gui=gtk2 \
    --enable-cscope \
    --prefix=/usr/local/vim
      make -j16
    }

  function install_from_yum {
    ## another way
    ## in order to support spacevim
    sudo wget -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/elyezer/vim-latest/repo/epel-7/elyezer-vim-latest-epel-7.repo
    sudo yum install -y vim
  }

function install_space_vim {
  ## install spacevim
  # https://spacevim.org/quick-start-guide/
  set -vx
  cd ~
  curl -sLf https://spacevim.org/install.sh | bash

  echo "make vimproc"
  cd ~/.SpaceVim/bundle/vimproc.vim && mkdir -p lib && make

  ##### YCM #############
  cd ~/.cache/vimfiles/repos/github.com/Valloric/YouCompleteMe
  git submodule update --init --recursive
  ./install.py
}

function install_space_vim_from_tgz {
  set -vx
  cd ~
  wget http://${MYVM}:38080/tools/SpaceVim.tgz
  tar zxf SpaceVim.tgz
  mv .vim .vim.bk.$(date +'%Y%m%d_%H%M%S')
  ln -svnf .SpaceVim .vim
}

function main {
  act=$1
  case $act in
    src)
      build_vim_prepare
      workdir=$HOME/tools/vim && mkdir -p $workdir && cd $workdir
      build_from_src
      ;;
    SpaceVim_tgz) install_space_vim_from_tgz;;
    SpaceVim_git) install_space_vim;;
    *) install_from_yum;;
  esac
}

main $@
