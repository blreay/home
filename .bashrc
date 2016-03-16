#!/bin/bash -f

[ -f ~/.`uname`_rc ] && . ~/.`uname`_rc
[ -f ~/.`hostname`_rc ] && . ~/.`hostname`_rc
[ -f /etc/bashrc ] && . /etc/bashrc

export EDITOR=vim

title() {
    echo -ne "\033]0;$1@${HOSTNAME}\007"
}

function set_proxy {
export HTTP_PROXY=http://cn-proxy.jp.oracle.com:80
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTP_PROXY
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


export NFSPATH=/nfs/users/zhaozhan
[[ ! -d $NFSPATH ]] &&  export NFSPATH=/home/zhaozhan/nfs_users_zhaozhan
export NFS=$NFSPATH
export PATH=$PATH:$ORACLE_HOME/bin:$NFSPATH/common/$OS/bin/bcmds:$NFSPATH/common/bin:$NFSPATH/common/$OS/bin:$NFSPATH/common/sh:$NFSPATH/common/sh/ART:$NFSPATH/common/sh/ART/appdir_create:/usr/vac/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/openwin/bin:/usr/X11/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/lib:/usr/local/lib:$NFSPATH/common/`uname -s`/lib

## COMMON ###
export CVSROOT=:pserver:zhaozhan@bjsrc.cn.oracle.com:/repos
export CVSLOG=$NFSPATH/_cvslog_important_do_NOT_delete
#[[ $HOME = "/nfs/users/zhaozhan" ]] && export DIR_TRASH=$NFS/gomihako || export DIR_TRASH=$HOME/gomihako
export DIR_TRASH=$HOME/gomihako && mkdir -p $DIR_TRASH >/dev/null 2>&1

## Can't set VIMRUNTIME,otherwise :help will not work 
#export VIMRUNTIME=$NFS/.vim 
export VIMRUNTIME=$HOME/.vim

export LANG=C
export EDITOR=vim
export MYM=zhaozhan@slc09wou.us.oracle.com

ulimit -c unlimited
alias ll='ls -l'
alias rm="$NFS/common/sh/myrm.sh"
exe="$NFSPATH/common/$OS/bin/vim" && [[ -f $exe ]] || exe="vim"
alias vim="TERM=xterm-256color $exe -X"
alias cit="source $HOME/cdcit.sh"
alias cit2="source $HOME/cdcit2.sh"
alias cmf="source $HOME/cdbatch.sh"
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
case ${OS} in
(Linux)
	#infocmp putty-256color >/dev/null 2>&1 && export TERM=putty-256color || export TERM=xterm
	export TERM=xterm-256color
	export TERMINFO=$NFS/.terminfo/$OS
	eval `dircolors $NFSPATH/.dir_colors`
	alias ls='ls --color=auto'
	exe="$NFSPATH/common/$OS/bin/tmux" && [[ -f $exe ]] || exe="tmux"
	#alias tmux="TERM=putty-256color $exe"
	#eval `dircolors $NFSPATH/.dir_colors`
	[[ -f $NFSPATH/.dir_colors ]] && dircolors $NFSPATH/.dir_colors > /dev/null
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
	which gls >/dev/null 2>&1 && { ldd $(which gls 2>/dev/null)|grep "found" >/dev/null 2>&1 || alias ls='gls --color=auto'; }
	;;
(AIX)
	#export TERM=screen-256color
	export TERM=putty-256color
	export TERMINFO=$NFS/.terminfo/$OS
	export VIMRUNTIME=$NFS/.vim
	export VIM=$NFS/.vim
	export PATH=$PATH:/opt/csw/bin:$NFSPATH/common/$OS/freeware/bin
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NFSPATH/common/$OS/freeware/lib
	;;
(*)
	;;
esac

case $(uname -n) in
(bej301713.cn.oracle.com) 
	export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
	export SANITYPATH=$HOME/sanity/cron/cvs_batch_sanity
	#export DEVPATH=~/dev/art/jes/art_MainBranch/jes.12cR2
	export DEVPATH=~/dev/art/jes/art_MainBranch/jes.jclexecutor/
	export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
 	;;
(bej301712.cn.oracle.com) 
	export SANITYPATH=$HOME/sanity/cron/cvs_batch_sanity
	#export DEVPATH=~/dev/art/jes/art_MainBranch/jes.jclexecutor/
	export DEVPATH=~/dev/tsam/agent
	export DEVJES=/home/zhaozhan/dev/art/jes/art_MainBranch/jes.12cR3
	export LD_LIBRARY_PATH=/usr/local/gcc-4.1.2/lib64:$LD_LIBRARY_PATH:/lib64:/usr/lib64:/usr/local/lib
 	;;
(*)
	export SANITYPATH=$NFSPATH/work_batchrt/mf/sanity/batchrt
	;;
esac

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
export PS1="$c3\u@$c1\h:$c2\w>$c_1"; 
export PS4='+{$0:$LINENO:${FUNCNAME[0]}} '
export  TZ='Asia/Shanghai'

## for PDKSH
export ENV=$HOME/.pdkshrc

#################                                            
## Welcome ##                                                
#echo "Welcome to `uname -s` (`uname -n`)"                   
# if not tty, dont' erase it                                 
[[ -t 1 ]] && stty erase '^?'                                
[[ -t 1 ]] && stty erase ^H 
[[ -t 1 ]] && stty erase '^?'
[[ -t 1 ]] && stty intr ^C
[[ -t 1 ]] && echo "Welcome to `uname -s` (`uname -n`)"      

