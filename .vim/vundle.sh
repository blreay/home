#!/bin/bash

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
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
