#!/bin/bash

function init_root {
	### for root
	export http_proxy=http://www-proxy.us.oracle.com:80
	export https_proxy=http://www-proxy.us.oracle.com:80
	yum install -y cvs vim zip lsof ksh git jq openssl

	groupadd -g 8500 dba || groupadd -g 8500 dba1
	adduser -d /home/zhaozhan -g 8500 -m -s /bin/bash -u 518713 zhaozhan
	usermod -a -G docker zhaozhan
	usermod -a -G root zhaozhan
	echo "zhaozhan    ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
	#add "zhaozhan    ALL=(ALL)   NOPASSWD: ALL" to /etc/sudoers

	curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o ./docker-compose
	sudo cp ./docker-compose /usr/bin
	sudo chmod +x /bin/docker-compose

	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	#cvs login
	echo '/1 :pserver:zhaozhan@bej301738.cn.oracle.com:2401/home/zhaozhan/repos As>a)4KRDh0%' > $HOME/.cvspass
	chmod a+r $HOME/.cvspass
	cd /u01/obcs/app/peer/run/
	cvs co -d *peer0 bcs/psmenv/zzy_bk
	/bin/rm /u01/obcs/app/peer/run/*peer0/peer.sh
	cp $(which cvs) /u01/obcs/app/peer/run/*peer0
	sudo su - oracle <<\EOF
		`init_oracle`
EOF
	### for zhaozhan
	su - zhaozhan <<\EOF
	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	echo '/1 :pserver:zhaozhan@bej301738.cn.oracle.com:2401/home/zhaozhan/repos As>a)4KRDh0%' > $HOME/.cvspass
	#cvs login
	cvs co home
	cd home && . ./.bashrc
	cd ~; myhomelink.sh -b; myhomelink.sh
	cd $NFS/common/sshkey && ./copykey.sh
	chmod a+rx $HOME
EOF
}

function init_oracle {
	cd ~
	mkdir mybox
	curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/patch/cvs -o mybox/cvs
	chmod a+x mybox/cvs
	export PATH=$PWD/mybox:$PATH
	pwd
	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	echo '/1 :pserver:zhaozhan@bej301738.cn.oracle.com:2401/home/zhaozhan/repos As>a)4KRDh0%' > $HOME/.cvspass
	#cvs login
	cvs co home
	curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/patch/mybox/git > $HOME/home/common/Linux/bin/git 
	curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/common/Linux/bin/jq > $HOME/home/common/Linux/bin/jq
	chmod +x $HOME/home/common/Linux/bin/git
	#https_proxy=http://www-proxy.us.oracle.com:80 curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o $HOME/home/common/Linux/bin/jq 
	chmod +x $HOME/home/common/Linux/bin/jq
	cd home && . ./.bashrc
	cd ~
	ln -svnf home/.vimrc .
	ln -svnf home/.vim .
	ln -svnf home/.tmux.conf .
	ln -svnf home/.tmux .
	git config --global user.name "zhaoyong.zhang@oracle.com"
	chmod 600 $HOME/home/common/sshkey/zzy01_rsa_private
	cd /u01/obcs/app/cpm
	export GIT_SSH=mygitwrapper.sh
	## as it's too slow, use nohup make it run in background, this is mandatory, becasue need to use ssh to launch this script, if just use "&" at the tail, ssh will not return.
	nohup git clone -b bcsdev-preview ssh://zhaoyong.zhang%40oracle.com@alm.oraclecorp.com:2222/fmwt_fabric_6187/BCS-deployment.git >/tmp/init.git.log 2>&1 </dev/null &
	nohup bash -c "cd /u01/obcs/app/console && git clone -b bcsdev-preview ssh://zhaoyong.zhang%40oracle.com@alm.oraclecorp.com:2222/fmwt_fabric_6187/BCS-deployment.git" >/tmp/console.git.log 2>&1 </dev/null &
	nohup bash -c "cd /u01/obcs/app/peer/pkg && curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/share/go_install.zip > ./go_install.zip && unzip ./go_install.zip" >/tmp/go.log 2>&1 </dev/null &
	#(cd BCS-deployment && git checkout bcsdev-preview)
	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	mkdir work
	cvs co -d work bcs/psmenv
	cp -r work /u01/obcs/app/peer/pkg
	cp -r work /u01/obcs/app/orderer/pkg
	LOGINCMD="$HOME/mybox/mysshshell.sh" && TELNET_LOCAL_PORT=7333
	${HOME}/mybox/busybox telnetd -l ${LOGINCMD:-/bin/bash} -p ${TELNET_LOCAL_PORT} 

	#### create tmux session
	. $HOME/home/.bashrc
	mytmux.sh -d
	send_cmd
	## if run in terminal
	[[ -t 0 && -t 1 && -t 2 && -t 3 ]] && mytmux.sh
}


function nousenow {
	## for remote access
	#/sbin/sshd -4 -p 10022
	su - zhaozhan -c mytmux.sh

	## For ACCS container: proxy or CA or CRC
	######################################
	export MYBINDIR=/u01/app
	touch $MYBINDIR/ttt || export MYBINDIR=$HOME/bin
	mkdir -p $MYBINDIR
	for f in mysshshell.sh mybox/busybox; do
		typeset DESTF=$MYBINDIR/${f##*/}
		echo download $f to $DESTF
		curl http://bej301738.cn.oracle.com/patch/$f > $DESTF
		chmod +x $DESTF
	done
	export PATH=$PATH:$MYBINDIR
	export PS1="\u@\h:\w>"
	echo export PS1='"\u@\h:\w>"'
	cat - <<\EOF >> $HOME/.bashrc
	#export PS1="\u@\h:\w>"
	export PS1="\[\e[33m\]\u@\[\e[31m\]\h:\[\e[32m\]\$(pwd)>\[\e[0m\]"
	EOF
	$MYBINDIR/mysshshell.sh

	## History for oracle
	mkdir /u01/obcs/app/cpm
	cd /u01/obcs/app/cpm
	cp /home/zhaozhan/provision/* .
	mkdir bin
	mkdir log
	cd bin
	mv ../bcs-cpm.zip .
	unzip bcs-cpm.zip
	cd ..
	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	cvs co bcs
	mv bcs/psmenv/* .
	rm -r bcs

	cd /u01/obcs/app/peer/pkg
	mv peer.sh peer.sh.bk.$(date +'%Y%m%d_%H%M%S')
	mv peer peer.bk.$(date +'%Y%m%d_%H%M%S')
	mv ./bcsagent ./bcsagent.$(date +'%Y%m%d_%H%M%S')
	cp /home/zhaozhan/provision/peer-cloud-201710191650 ./peer
	cp /home/zhaozhan/provision/peer.sh ./peer.sh
	cp /home/zhaozhan/provision/bcsagent-201710191650 ./bcsagent

	cd /u01/obcs/app/peer/etc
	for i in *.env; do echo $i; chmod u+w $i; echo "BCS_CPM_URL=http://10.89.105.213:7359" >> $i; done
	for i in *.env; do echo $i; chmod u+w $i; echo "CORE_LOGGING_LEVEL=DEBUG" >> $i; done
EOF 

	scp -r 10.89.106.214:/home/zhaozhan/provision /home/zhaozhan/
	ssh bejan08-4.cn.oracle.com "cd /home/zhaozhan/bcsenv2/zip_bk; tar zcvf - bcs-ca.zip  bcs-console.zip  bcs-gateway.zip  bcs-orderer.zip  bcs-peer.zip  go_install" | tar zxvf -


	cd /u01/obcs/app
	export GIT_SSH=mygitwrapper.sh


	for _pane in $(tmux list-panes -a -F '#{pane_id}'); do 
		tmux send-keys -t ${_pane} 'sudo su - oracle'  C-m
		sleep 1
		tmux send-keys -t ${_pane} '. home/.bashrc'  C-m
	done
	. ~/home/.bashrc
	cd /u01/obcs/app/cpm
	export GIT_SSH=mygitwrapper.sh
	alias b=/u01/obcs/app/cpm/work/bcs.sh; alias o=/u01/obcs/app/cpm/work/open.sh
	export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos
	export MYDBG=DEBUG

	cd $HOME
	./mybox/dbclient -I 0 -K 99999 -y -g -i ./mybox/privateKey.dropbear -N -l bcs -o ExitOnForwardFailure=yes -p 22 -R bej301738.cn.oracle.com:40022:0.0.0.0:10022 bej301738.cn.oracle.com
	./mybox/dbclient -I 0 -K 99999 -y -g -i ./mybox/privateKey.dropbear -N -l bcs -o ExitOnForwardFailure=yes -p 22 -R bej301738.cn.oracle.com:40021:0.0.0.0:10021 bej301738.cn.oracle.com
	./mybox/dbclient -I 0 -K 99999 -y -g -i ./mybox/privateKey.dropbear -N -l bcs -o ExitOnForwardFailure=yes -p 22 -R bej301738.cn.oracle.com:40024:0.0.0.0:10024 bej301738.cn.oracle.com
	./mybox/dbclient -I 0 -K 99999 -y -g -i ./mybox/privateKey.dropbear -N -l bcs -o ExitOnForwardFailure=yes -p 22 -R bej301738.cn.oracle.com:40069:0.0.0.0:10069 bej301738.cn.oracle.com

	cat - <<EOF >> $HOME/.ssh/authorized_keys
	ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA3w4t0oXI8++6AKTZ48v3a2i8xtqTaWXKCwfDhetDz0R2fmI34kr9S2Fs5C2bE0QYSxbD1ztOpnQzEyHw2E+scc4/qR8DxWdJeYJ6GYiSfY0FgMjOI/07+DU/bPc7rrTzlo8qXPvCeSTi1SLvyIdRtW3wrKprdX8wXWGcymHMr2p9cHg5iLyH4H2joMaDR1CItKuqv7vjfQE+r4ITqsG4tC/XWMhRhfbM14p7Z3RS0iy9A2QxifUM4IlWovxnO5mJbrhZUwZaIqsMmLx7FhNO9vd2d0nUoMnwIncuprxwpjjHi0JMwuvqI8F5/xtvVQboXWt5Rjo1JnO2yKQYvI50sQ== rsa-key-20160226
EOF

	## for root
	APP_HOME=/root
	PATCHFILE=mybox.zip \
	&& TMPFN="$APP_HOME/patch_$(date +'%Y%m%d_%H%M%S').zip" \
	&& curl http://bej301738.cn.oracle.com:${WEBPORT:-80}/patch/$PATCHFILE -o $TMPFN \
	&& unzip -l $TMPFN \
	&& cd $APP_HOME \
	&& unzip -o $TMPFN \
	&& echo "patch OK"
	LOGINCMD="$APP_HOME/mybox/mysshshell.sh" && TELNET_LOCAL_PORT=7333
	${APP_HOME}/mybox/busybox telnetd -l ${LOGINCMD:-/bin/bash} -p ${TELNET_LOCAL_PORT}


	https_proxy=http://www-proxy.us.oracle.com:80 curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq && chmod +x /usr/bin/jq


	mytmux.sh -c "sudo su - oracle"
	mytmux.sh -c ". ~/home/.bashrc"
	mytmux.sh -c "cd /u01/obcs/app/cpm"
	mytmux.sh -c "export GIT_SSH=mygitwrapper.sh"
	mytmux.sh -c "export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos"
	mytmux.sh -c "export MYDBG=DEBUG"
	mytmux.sh -c "export PATH=$PATH:/u01/obcs/app/cpm/work"
	mytmux.sh -c "mysshshell.sh"
	mytmux.sh -c "source ~/home/.bashrc"
	mytmux.sh -c "alias b=/u01/obcs/app/cpm/work/bcs.sh; alias o=/u01/obcs/app/cpm/work/open.sh"
	mytmux.sh -c ". /u01/obcs/app/cpm/work/setenv.prov.sh old"
}

## For peer
###==========
function send_cmd {
	export app=${1:-peer}
	export pkgpath=/u01/obcs/app/${app:-peer}/pkg
	
	source ~/home/.bashrc
	#mytmux.sh -c "sudo su - oracle"
	mytmux.sh -f -c ". ~/home/.bashrc"
	mytmux.sh -f -c "cd ${pkgpath}"
	mytmux.sh -f -c "export GIT_SSH=mygitwrapper.sh"
	mytmux.sh -f -c "export CVSROOT=:pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos"
	#mytmux.sh -f -c "export MYDBG=DEBUG"
	mytmux.sh -f -c "export PATH=$PATH:${pkgpath}/work"
	mytmux.sh -f -c "mysshshell.sh"
	mytmux.sh -f -c "source ~/home/.bashrc"
	mytmux.sh -f -c "alias b=${pkgpath}/work/bcs.sh; alias o=${pkgpath}/work/open.sh; alias or=${pkgpath}/work/ordereradm.sh; "
	mytmux.sh -f -c "alias c=${pkgpath}/work/bcsclient.sh"
	mytmux.sh -f -c "cd ${pkgpath}/work"
	#mytmux.sh -c ". /u01/obcs/app/cpm/work/setenv.prov.sh old"
}

#################################################################
# init_oracle init_root nousenow
act=${1:-"init_oracle"}
shift 1
${act} $@

