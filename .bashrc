#!/bin/bash -f

[ -f ~/.`uname`_rc ] && . ~/.`uname`_rc
[ -f ~/.`hostname`_rc ] && . ~/.`hostname`_rc
[ -f /etc/bashrc ] && . /etc/bashrc

export EDITOR=vim
MYID=zhaozhan
[[ -d /home/${MYID} ]] && MYHOME=/home/${MYID} || MYHOME=$HOME

title() {
    echo -ne "\033]0;$1@${HOSTNAME}\007"
}

function set_proxy {
[[ "no" == "$1" ]] && unset http_proxy HTTP_PROXY https_proxy ftp_proxy && echo "proxy has been disabled $(env|grep -i proxy)" && return
export HTTP_PROXY=http://cn-proxy.jp.oracle.com:80
[[ "us" == "$1" ]] && export HTTP_PROXY=http://www-proxy.us.oracle.com:80
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTP_PROXY
export ftp_proxy=$HTTP_PROXY
env|grep -i proxy
}
function set_java {
export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$DERBY_HOME/bin:NFS/application/Linux/eclipse:$PATH
export LD_LIBRARY_PATH=$JAVA_HOME/lib:$MAVEN_HOME/lib:$DERBY_HOME/lib:$LD_LIBRARY_PATH
}

function set_cn {
export LANG="zh_CN.UTF-8"
export LC_ALL="zh_CN.UTF-8"
}

function set_vimrc {
vimnewrc1=$NFS/.vim/.vimrc.conf
vimnewrc2=$HOME/.vim/.vimrc.conf
while read line; do eval $line; done <<-EOF
$({ test -f $vimnewrc1 && DISPLAY= gpg -o - $vimnewrc1 2>/dev/null; }  || { test -f $vimnewrc2 && DISPLAY= gpg -o - $vimnewrc2 2>/dev/null; })
EOF
}

function jesdate {
perl <<-\EOF
use Time::HiRes;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
($s, $usec) = Time::HiRes::gettimeofday();
printf("%04d%02d%02d %02d:%02d:%02d.%03d\n", $year+1900, $mon+1, $mday+1, $hour, (($s-$s%60)/60)%60, $s%60, $usec/1000);
EOF
}

OS=$(uname -s)
[[ $OS == CYGWIN* ]] && OS=win
[[ -z $USER ]] && export USER=$(id -un 2>/dev/null)
[[ -z $USER ]] && export USER=$(/usr/xpg4/bin/id -un)

export NFSPATH=/nfs/users/zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=/home/zhaozhan/nfs_users_zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=/nfs/homes/zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=/nfs/ucfhomes/zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=/home/zhaozhan/nfs_local
[[ ! -d $NFSPATH ]] && export NFSPATH=/u01/common/patches/zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=$HOME/nfs_local/home
[[ ! -d $NFSPATH ]] && export NFSPATH=$HOME/home
[[ ! -d $NFSPATH ]] && [[ -d $PWD/common/sh ]] && export NFSPATH=$PWD
[[ ! -d $NFSPATH ]] && export NFSPATH=/home/zhaozhan/home
[[ ! -d $NFSPATH ]] && export NFSPATH=/home/zhaozhan
[[ ! -d $NFSPATH ]] && export NFSPATH=$HOME
export NFS=$NFSPATH
export PATH=$PATH:$ORACLE_HOME/bin:$NFSPATH/common/$OS/bin/bcmds:$NFSPATH/common/bin:$NFSPATH/common/$OS/bin:$NFSPATH/common/sh:$NFSPATH/common/sh/ART:$NFSPATH/common/sh/ART/appdir_create:/usr/vac/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/openwin/bin:/usr/X11/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/lib:/usr/local/lib:$NFSPATH/common/`uname -s`/lib

## COMMON ###
#export CVSROOT=:pserver:zhaozhan@bjsrc.cn.oracle.com:/repos
#export CVSROOT=":ext;privatekey=$(echo ~zhaozhan)/.ssh/id_rsa:zhaozhan@bjsrc.cn.oracle.com:/repos"
export CVSROOT=":ext:zhaozhan@bjsrc.cn.oracle.com:/repos"
export CVS_RSH=ssh
#if [[ $USER = @(zhaozhan|opc) ]]; then
export MYCVSROOT=":pserver:zhaozhan@bej301738.cn.oracle.com:/home/zhaozhan/repos"
alias s=set_vimrc
#fi
export CVSLOG=$NFSPATH/_cvslog_important_do_NOT_delete
#[[ $HOME = "/nfs/users/zhaozhan" ]] && export DIR_TRASH=$NFS/gomihako || export DIR_TRASH=$HOME/gomihako
export DIR_TRASH=$HOME/gomihako && mkdir -p $DIR_TRASH >/dev/null 2>&1
export SH=$NFS/common/sh
export SHR=$NFS/share

## Can't set VIMRUNTIME,otherwise :help will not work 
#export VIMRUNTIME=$NFS/.vim 
export VIMRUNTIME=$HOME/.vim

export LANG=C
export EDITOR=vim
export MYM=zhaozhan@slc09wou.us.oracle.com
export MYPC=$(who |grep $USER | grep "${SSH_TTY/\/dev\/}" | awk '{print $NF}' | uniq | sed 's/(//g;s/)//g')

ulimit -c unlimited
alias ll='ls -l'
alias rm="$NFS/common/sh/myrm.sh"
vimexe="$NFSPATH/common/$OS/bin/vim" && [[ -f $vimexe ]] || vimexe="vim"
#alias vim="TERM=xterm-256color $vimexe -X"
alias vim="TERM=xterm-256color VIMRUNTIME=$MYHOME/.vim $vimexe -X --cmd \"set runtimepath^=$MYHOME/.vim\" --cmd \"set runtimepath+=$MYHOME/.vim/bundle/Vundle.vim\" -u $MYHOME/.vimrc"
alias cit="source $NFS/cobset.sh cit"
alias cit2="source $NFS/cobset.sh cit"
alias cmf="source $NFS/cobset.sh mf"
alias cno="source myinit.sh"
alias cgo="cd \$MT_ROOT/SOURCE && . ./setenv.sh"
alias CD='cd $(pwd -P)'
alias git_proxy="git config --global http.proxy http://cn-proxy.jp.oracle.com:80"
alias myproxy=set_proxy
alias mydate="date +'%Y%m%d %H:%M:%S.%N'"
alias le="myjesps.sh |grep \"EJR -e \""
alias lj="ls -alrt \$JESROOT/runningjobs/*"
alias lc='cat \$JESROOT/artjes2_jobid;echo'
alias jl="artjesadmin -x showjobexec; myqmsgcount.sh ;lj"
alias mydb2="source mysetdb.sh"
alias d="docker "
alias ds="docker service "
alias dstk="docker stack "
alias g="git "
alias cdvm="cd $NFS/bcs/psmenv.cvs/vm/"
alias setbcs="cd $NFS/bcs/psmenv.cvs && . ./setenv.sh && cd -"
case ${OS} in
(Linux)
	#infocmp putty-256color >/dev/null 2>&1 && export TERM=putty-256color || export TERM=xterm
	export TERM=xterm-256color
	export TERMINFO=$NFS/.terminfo/$OS
	alias ls='ls --color=auto'
	exe="$NFSPATH/common/$OS/bin/tmux" && [[ -f $exe ]] || exe="tmux"
	#alias tmux="TERM=putty-256color $exe"
	alias tmux="$exe -2u"
	#[[ -f $NFSPATH/.dir_colors ]] && dircolors $NFSPATH/.dir_colors > /dev/null
	#eval `dircolors $NFSPATH/.dir_colors`
	export PATH=$NFSPATH/common/$OS/bin:$PATH 
	;;
(SunOS)
	#set TERM=sun-color
	#export TERM=sun-color
	#export TERM=putty-256color
	export TERM=xterm-256color
	export TERMINFO=$NFS/.terminfo/$OS
	exe="$NFSPATH/common/$OS/bin/tmux" && [[ -f $exe ]] || exe="tmux"
	alias tmux="TERM=putty-256color $exe"
	export VIMRUNTIME=$NFS/.vim
	export VIM=$NFS/.vim
	export PATH=/usr/xpg4/bin:$PATH:/opt/csw/bin::$NFS/application/SunOS/csw/bin
	#ldd $(which gls)|grep "found" >/dev/null 2>&1 || alias ls='gls --color=auto'
	#which gls >/dev/null 2>&1 && { ldd $(which gls 2>/dev/null)|grep "found" >/dev/null 2>&1 || alias ls='gls --color=auto'; }
	which gls 2>&1 | grep -v "no gls" >/dev/null 2>&1 && { ldd $(which gls 2>/dev/null)|grep "found" >/dev/null 2>&1 || alias ls='gls --color=auto'; }
	export LD_LIBRARY_PATH=/usr/sfw/lib/64:$LD_LIBRARY_PATH:/usr/sfw/lib
	;;
(AIX)
	#export TERM=screen-256color
	export TERM=putty-256color
	export TERMINFO=$NFS/.terminfo/$OS
	export VIMRUNTIME=$NFS/.vim
	export VIM=$NFS/.vim
	export PATH=$PATH:/opt/csw/bin:$NFSPATH/common/$OS/freeware/bin
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NFSPATH/common/$OS/freeware/lib
	which gls 2>&1 | grep -v "no gls" >/dev/null 2>&1 && { ldd $(which gls 2>/dev/null)|grep "found" >/dev/null 2>&1 || alias ls='gls --color=auto'; }
	exe="$NFSPATH/common/$OS/bin/tmux" && [[ -f $exe ]] || exe="tmux"
	alias tmux="TERM=putty-256color $exe -2u"
	;;
(*)
	;;
esac

[[ -n "$(which rlwrap 2>/dev/null)" ]] && alias sqlplus='rlwrap sqlplus' && alias ij='rlwrap ij'

case $(uname -n) in
(bej301713.cn.oracle.com) 
	export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
	export SANITYPATH=$HOME/sanity/cron/cvs_batch_sanity
	export DEVJES=~/dev/art/jes/art_MainBranch/jes.12cR3
	export JAVA_HOME=$NFS/application/Linux/jdk1.8.0_74
	export MAVEN_HOME=$NFS/application/Linux/apache-maven-3.5.0
	export DERBY_HOME=$NFS/application/Linux/db-derby-10.13.1.1-bin
	export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
 	;;
(bej301712.cn.oracle.com) 
	export SANITYPATH=$HOME/sanity/cron/cvs_batch_sanity
	#export DEVPATH=~/dev/art/jes/art_MainBranch/jes.jclexecutor/
	export DEVPATH=~/dev/tsam/agent
	export DEVJES=/home/zhaozhan/dev/art/jes/art_MainBranch/jes.12cR3
	export JAVA_HOME=$NFS/application/Linux/jdk1.8.0_74
	export MAVEN_HOME=$NFS/application/Linux/apache-maven-3.5.0
	export DERBY_HOME=$NFS/application/Linux/db-derby-10.13.1.1-bin
	#export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
	## for wine process
	[[ $USER == "zhaozhan" ]] && { export MYDBG_SHOWALL=yes && export MYDBG_SHOWDBG=DEBUG0; }
	[[ $USER != "zhaozhan" ]] && { unset MYDBG_SHOWALL MYDBG_SHOWDBG; }
 	;;
(bej301738.cn.oracle.com) 
	export DEVJES=/home/zhaozhan/dev/art/jes/art_MainBranch/jes.12cR3
	export DEVTMA=/home/zhaozhan/dev/tma
	export JAVA_HOME=$NFS/application/Linux/jdk1.8.0_74
	export MAVEN_HOME=$NFS/application/Linux/apache-maven-3.5.0
	export DERBY_HOME=$NFS/application/Linux/db-derby-10.13.1.1-bin
	 #[[ $USER != "zhaozhan" ]] && { alias vim="TERM=xterm-256color VIMRUNTIME=/home/zhaozhan/.vim $vimexe -X --cmd \"set runtimepath^=/home/zhaozhan/.vim\" --cmd \"set runtimepath+=/home/zhaozhan/.vim/bundle/Vundle.vim\" -u /home/zhaozhan/.vimrc"; }
	 [[ "$USER" != "${MYID}" ]] && { alias vim="TERM=xterm-256color VIMRUNTIME=$MYHOME/.vim $vimexe -X --cmd \"set runtimepath^=$MYHOME/.vim\" --cmd \"set runtimepath+=$MYHOME/.vim/bundle/Vundle.vim\" -u $MYHOME/.vimrc"; }
 	;;
(bej301459*) 
	 ## for wine process
	 [[ $USER == "zhaozhan" ]] && { export MYDBG_SHOWALL=yes && export MYDBG_SHOWDBG=DEBUG0; }
	 [[ $USER != "zhaozhan" ]] && { unset MYDBG_SHOWALL MYDBG_SHOWDBG; }
 	;;
(slc09wou*) 
	 vimexe="/usr/bin/vim"
	 alias vim="TERM=xterm-256color VIMRUNTIME=$MYHOME/.vim $vimexe -X --cmd \"set runtimepath^=$MYHOME/.vim\" --cmd \"set runtimepath+=$MYHOME/.vim/bundle/Vundle.vim\" -u $MYHOME/.vimrc"
	 ## for wine process
	 [[ $USER == "zhaozhan" ]] && { export MYDBG_SHOWALL=yes && export MYDBG_SHOWDBG=DEBUG0; }
	 [[ $USER != "zhaozhan" ]] && { unset MYDBG_SHOWALL MYDBG_SHOWDBG; }
 	;;
(rno05038) 
	 [[ $USER == "zhaozhan" ]] && export CVS_PASSFILE=$NFS/.cvspass
	 [[ $USER != "zhaozhan" ]] && { alias vim="TERM=xterm-256color $vimexe -X -u /home/zhaozhan/.vimrc"; }
	alias cvs=/usr/bin/cvs
 	;;
(burf07cn05) 
	## remove sfw/lib/64
	export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH|sed 's/[^:]*\/usr\/sfw\/lib\/64[^:]*//g')
 	;;
(burf07cn10|slc10avp) 
	alias cvs=$NFS/common/SunOS/bin/cvs
	## remove sfw/lib/64
	#export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH|sed 's/[^:]*\/usr\/sfw\/lib\/64[^:]*//g')
	eval `/usr/openwin/bin/resize`
	shopt -s checkwinsize
	export TERM=$TERM
 	;;
(bej301159) 
	exe="$NFSPATH/common/$OS/bin/vim.static" && [[ -f $exe ]] || exe="vim"
	alias vim="TERM=xterm-256color $exe -X"
	;;
(bejan08-?.cn.oracle.com) 
	exe="/usr/bin/vim" && [[ -f $exe ]] || exe="vim"
	alias vim="TERM=xterm-256color $exe -X"
	;;
(ZHAOZHAN-CN) 
	export PATH=/bin:/usr/bin:/sbin:$PATH
	exe="/usr/bin/vim" && [[ -f $exe ]] || exe="vim"
	alias vim="TERM=xterm-256color $exe -X"
	alias tmux="tmux"
	;;
(*)
	export SANITYPATH=$NFSPATH/work_batchrt/mf/sanity/batchrt
	;;
esac

export DEVBP=/nfs/users/zhaozhan/dev/batchplus/src

##### SET prompt color #####
c_1="\[\e[0m\]"
c0="\[\e[30m\]"
c1="\[\e[31m\]"
c2="\[\e[32m\]"
c3="\[\e[33m\]"
c4="\[\e[34m\]"
c5="\[\e[35m\]"
c6="\[\e[36m\]"
c7="\[\e[37m\]"
#export PS1="$c3\u$c5[\!]$c2\w>$c_1";
#export PS1="$c0***** $c1\w $c2*** $c3<\u@\h> $c4***** $c5\! $c6***** $c7\t $c1***$c2\$ $c_1";
#export PS1="$c3\u$c1[\!]$c2\w>$c_1";
#export PS1="$c3\u@$c1\h:$c2\w>$c_1"; 
export PS1="$c3\u@$c1\h:$c2\$(pwd)>$c_1"; 
export PS4='+{$0:$LINENO:${FUNCNAME[0]}} '
export  TZ='Asia/Shanghai'
export LS_COLORS='rs=0:di=01;37;44:ln=04;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.tbz=01;31:*.tbz2=01;31:*.bz=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.axa=01;36:*.oga=01;36:*.spx=01;36:*.xspf=01;36:'

## for PDKSH
export ENV=$HOME/.pdkshrc

## for chinese input
#export GTK_IM_MODULE=ibus
#export XMODIFIERS=@im=ibus
#export QT_IM_MODULE=ibus

export LC_CTYPE="zh_CN.UTF-8"
export XIM=fcitx
export XIM_PROGRAM=fcitx
export GTK_IM_MODULE=xim
export XMODIFIERS="@im=fcitx"

##expand environment variable when press TAB
shopt -s direxpand

#################                                            
## Welcome ##                                                
#echo "Welcome to `uname -s` (`uname -n`)"                   
# if not tty, dont' erase it                                 
[[ -t 1 ]] && stty erase '^?'                                
[[ -t 1 ]] && stty erase ^H 
[[ -t 1 ]] && stty erase '^?'
[[ -t 1 ]] && stty intr ^C
[[ -t 1 ]] && echo "Welcome to `uname -s` (`uname -n`) from (${MYPC})"
