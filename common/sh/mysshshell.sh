#!/bin/bash

################################################################
typeset KEYFILE=/tmp/.zkey.lock.$USER
typeset MYUSER=zhaozhan
typeset MYSVR=bej301738.cn.oracle.com
typeset MYPCPORT=30022
################################################################

[[ ! -f ${KEYFILE} ]] && {
cat - <<\EOF > ${KEYFILE}
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA3w4t0oXI8++6AKTZ48v3a2i8xtqTaWXKCwfDhetDz0R2fmI3
4kr9S2Fs5C2bE0QYSxbD1ztOpnQzEyHw2E+scc4/qR8DxWdJeYJ6GYiSfY0FgMjO
I/07+DU/bPc7rrTzlo8qXPvCeSTi1SLvyIdRtW3wrKprdX8wXWGcymHMr2p9cHg5
iLyH4H2joMaDR1CItKuqv7vjfQE+r4ITqsG4tC/XWMhRhfbM14p7Z3RS0iy9A2Qx
ifUM4IlWovxnO5mJbrhZUwZaIqsMmLx7FhNO9vd2d0nUoMnwIncuprxwpjjHi0JM
wuvqI8F5/xtvVQboXWt5Rjo1JnO2yKQYvI50sQIBJQKCAQEAqMx1tBI3NSQeDlM9
Gxbkv/w71MEVm95TtVH7v0pBJzq6iSe7ln3wHV576vIUfUhJvEiUNCzhkrjMtIhj
O+lEOnKRClyo6GnWvNFxKBRTLpQ7hA2VFFDvHLKsic/aI1iA/FCqb+EdjBvp7WaL
8bKDBdaoS1CIq/GMYle07C5VtSyUWjPItTHBCOJGC0kiDjoaKTaLOLe1rusIj2xu
cFdI9vb+tsxW5xjBbPDGuA13oFjO6R3GHBHiONT+YcSTIgWr+Buqbtl8HUlrGydV
6Vs6gWNlbrz34D1Yc5Jrh7ivRNo+UMGuANmpLIk64qBq6y1h7wr0CgCqtuX+cugB
V/MzrQKBgQDyhz0GjvjfLVqlJHtb3W4en94inkXJmlo4yTBRx4+8Vg3q81p5QkSw
VBBDKClN4vlsBNHAjN3fRobM2CQG91G2GVlK1fL7u+VEcrvpOhVzTK+xbHCH+fTa
WPhsNQSwTi/+y8gsZkjD+EMjLGQkxalOAqbS8rhEbWTXJqRbA+HWIQKBgQDrcgkO
U3jFC/f9Wxg6aV7HguoHBDoy8l4oTV3mzr6lF8lAYZauklFmDvLogvAUkiutSoaG
oSQeGA2nW/ALji4LhF8R2E9oG4AxePpODDMFNij/Aai79V9zMMZrNTqPmHqtQnox
STpiDBIkcGNPj3PrOlGatAEPIsyq000pqQaskQKBgQCQNLyAcK+nS2ZUWuGQkX+/
Lp/BjopcMkN7teVhDt/XxHb6Zy7gUOqSW39KhpUZjeBpva0mYZiuRZxCcq2jRvJQ
mXNc7epsKohSNmHknxOsVxxbqELpESnN77ZOLVy723Z70x0TexaCXEOYX5V9pfX3
CH7eSyF0y2xkQH1mjK/LbQKBgQC4ic+/HtRHaj7pK7kLL/4tq8wvA1A1xOID6Zyg
JYCq6SEydgB6/Q9d1F2Fzmkk4UTT7k3Dd2F/XvXx4EaFmPOoKXryT5gvAMxCc5PA
occfwqqCrkX7GkPkqbBGMKOFTf9JhyGAk1dF7ckHzbWfORWqh6e+cWidKRz0l8bb
dqRdvQKBgHmHYsuLuD1yrQc8sZRR0ATEkdQaaEmwf7GV8k3sJt6Pnt48LLd4yLEY
xx6RBOmCl1UGs1J6dj4+uHKjk/wsqcK5Z9XMAFGP9nyXKiytn+4tnDoNdLyZ2BgB
d/buPT5/mr1Fy/Wd0b4tmwNjP2xWyLGR9bG+CLCejVigpkpA+o2q
-----END RSA PRIVATE KEY----- 
EOF
chmod 600 ${KEYFILE}
}

eval `ssh-agent -s`
ssh-add ${KEYFILE}
export MYNFS=$MYUSER@$MYSVR:/nfs/users/zhaozhan
export MYSHR=$MYNFS/share
export MYSCP="scp -P $MYPCPORT -o StrictHostKeyChecking=no $MYUSER@$MYSVR:/shr"
export MYPCSCP="function MYPCSCP { port=30022; shr=zhaozhan@bej301738.cn.oracle.com:/shr; f1=; f2=;  if [[ \$1 == 'from' ]]; then shift 1; f1=\$1; f2=\$2;	echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \$shr/\${f1} \${f2}; set +vx;else f1=\$1; f2=\$2; echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \${f1} \$shr/\${f2}; set +vx;fi; }; MYPCSCP " 
export MYNFSCP="function MYNFSCP { port=22; shr=zhaozhan@bej301738.cn.oracle.com:/nfs/users/zhaozhan/share; f1=; f2=;  if [[ \$1 == 'from' ]]; then shift 1; f1=\$1; f2=\$2;	echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \$shr/\${f1} \${f2}; set +vx;else f1=\$1; f2=\$2; echo \${f1}_\${f2}; set -vx; scp -P \$port -o StrictHostKeyChecking=no -r \${f1} \$shr/\${f2}; set +vx;fi; }; MYNFSCP "

echo "\$0=$0"

## open shell
if [[ ! "$0" =~ ^(/bin/bash|/bin/sh|-bash|bash)$ ]]; then
	echo "Enter shell ($SHELL) with ssh auto authentication"
	$SHELL
	## clean
	ssh-agent -k
	rm -f "${KEYFILE}"
	exit
fi
