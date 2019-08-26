#!/bin/bash

VER=3.6.0

TMPDIR=$HOME/tmp
wget https://www-us.apache.org/dist/maven/maven-3/${VER}/binaries/apache-maven-${VER}-bin.tar.gz -P ${TMPDIR}
sudo tar xf ${TMPDIR}/apache-maven-${VER}-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-${VER} /opt/maven

#sudo nano /etc/profile.d/maven.sh 

#if there is IO redirection in the command line, must use sudo bash -c to make sure the whole command line is exeucted by root
sudo bash -c 'cat - <<EOF > /etc/profile.d/maven.sh
export JAVA_HOME=/usr/lib/jvm/jre-openjdk
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF
'
sudo chmod a+x /etc/profile.d/maven.sh
cat /etc/profile.d/maven.sh
