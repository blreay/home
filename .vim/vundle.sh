#!/bin/bash

###############################################
# Set bash global option
###############################################
set -o posix
set -o pipefail
shopt -s expand_aliases
shopt -s extglob
shopt -s xpg_echo
shopt -s extdebug

###############################################
# global variables
typeset g_appname

:<<EOF
https://zhuanlan.zhihu.com/p/39516694
安装GitHub for macOS；
使用以下命令，将Vundle安装到指定目录：
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
安装后目录结构如下：

4. 将vimrc配置文件中的"set the runtime path to include Vundle and initialize部分，更新如下：
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
EOF

###############################################################
[[ ! -d ~/.vim/bundle ]] && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
. ~/.bashrc
type vim
vim +PluginInstall +qall

#show c/c++ function list
sudo yum install -y cscope ctags

