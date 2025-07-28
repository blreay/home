#!/bin/bash

#run with normal user
set -e

export VER="2.23.0"
if [[ ! -d git-$VER ]]; then
	wget https://github.com/git/git/archive/v${VER}.tar.gz
	tar -xvf v${VER}.tar.gz
	#rm -f v${VER}.tar.gz
fi

cd git-$VER
make clean
make prefix=/usr/local/git -j 16 all
sudo make prefix=/usr/local/git -j 16 install 

cd /usr/local/git/bin 
for i in *; do 
	echo $i
	sudo ln -svnf $PWD/$i /usr/bin/
done

sudo yum install -y git-lfs

which git
git --version
