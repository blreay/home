#!/bin/bash

wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod 755 /bin/jq

#wget -O /bin/git https://github.com/git/git/archive/v2.23.0.tar.gz
#chmod 755 /bin/git

yum groupinstall -y "Development Tools"
yum install -y xauth xclock
yum install -y libasan libasan-static
yum install -y wget perl-CPAN gettext-devel perl-devel  openssl-devel  zlib-devel
yum install -y cvs vim zip lsof ksh git jq openssl expect ftp perl
yum install -y gcc-c++ cmake3 automake autoconf perl-Thread-Queue libtool openssl zlib-devel strace ltrace iotop ctags cscope gdb
yum install -y libcurl-devel expat-devel jre-openjdk java maven enca
yum install -y libatomic libatomic-static libstdc++ libstdc++-static
yum install git-m -b test -y

ln -svnf $(which cmake3) /usr/bin/cmake

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
cat /etc/selinux/config
