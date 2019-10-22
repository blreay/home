#!/bin/bash

# 安装libunwind
wget http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz
tar zxvf libunwind-1.1.tar.gz
cd  libunwind-1.1
mkdir install
#./configure
./configure --PREFIX=$PWD/install
make && make install


# 安装gperftools
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz
tar zxvf gperftools-2.7.tar.gz
cd gperftools-2.7
#./configure
./configure --PREFIX=$PWD/install
make && make install

# 配置动态链接库管理
# echo "/usr/local/lib" >> /etc/ld.so.conf.d/usr_local_lib.conf
# ldconfig

