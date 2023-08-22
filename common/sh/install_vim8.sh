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
  ## if python3 is 3.6.8, must use pyhton3-devel-3.6.8, otherwise vim start fail
  ## but the default is python3-devel-3.8 if run: yum install python3-devel
  sudo yum install -y python3 python3-devel-3.6.8

}

function build_from_src {
  set -vx
  url=https://github.com/vim/vim/archive/v8.2.1153.zip
  wget ${url}
  zip=${url##*/}
  dir=$(unzip -l ${zip} | grep CONTRIBUTING.md | awk '{print $NF}' | cut -d '/' -f 1)
  /bin/rm -rf ${dir:-NOVAL}
  unzip ${zip}
  cd ${dir}
  mkdir myinstall
  pwd
  #--enable-gui=yes --enable-gtk2-check --with-x \
  # --enable-gui=gtk2 \
  #SRCDIR= ./configure --with-features=huge \
  ### NOTE: must make sure python3 is the correct executable file, especially conda is enabled
  ### confirm it with which -a python3
  ### SRCDIR has been exported by myself for project source code dir, must set it to empty
  ### because ./configure command will use it
  SRCDIR="" ./configure --with-features=huge \
    --enable-multibyte \
    --enable-python3interp \
    --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu \
    --enable-cscope \
    --prefix=$(pwd)/${dir}/myinstall
  make -j16
  sudo make install
  sudo cp -P /usr/local/vim/bin/* /usr/local/bin/
}

  function install_from_yum {
    ## another way, will install vim 8.0
    sudo wget --no-check-certificate -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/elyezer/vim-latest/repo/epel-7/elyezer-vim-latest-epel-7.repo
    sudo yum install -y vim
    # if you meet following error, run "" rpm -e --nodeps vim-minimal ""
    #Transaction check error:
    #file /usr/share/man/man1/vim.1.gz from install of vim-common-2:8.0.069-1.el7.centos.x86_64 conflicts with file from package vim-minimal-2:7.4.160-3.4.alios7.x86_64
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
  act=${1:-"src"}
  case $act in
    src)
      ## this is the best way, suppory SpaceVim, will install vim8.2
      build_vim_prepare
      workdir=$HOME/tools/vim && mkdir -p $workdir && cd $workdir
      build_from_src
      ;;
    SpaceVim_tgz) install_space_vim_from_tgz;;
    SpaceVim_git) install_space_vim;;
    ### will install vim8.0 which donot support SpaceVim
    *) install_from_yum;;
  esac
}

main $@
