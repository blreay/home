#!/bin/bash

[[ -z $HOME ]] && echo "HOME is NULL" && exit 1

mkdir -p $HOME/.ssh

echo "Copy key files"
#Bxxxxxxx@xxx
cat - <<EOF > $HOME/.ssh/id_rsa
`gpg -o - 1.gpg 2>/dev/null`
EOF
cat - <<EOF > $HOME/.ssh/id_rsa.pub
`gpg -o - 2.gpg 2>/dev/null`
EOF
cat - <<EOF > 1.ppk
`gpg -o - 1.ppk.gpg 2>/dev/null`
EOF
cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

chmod 600 $HOME/.ssh/id_rsa*
chmod 600 $HOME/.ssh/authorized_keys
echo "Checing SELinux: $(getenforce)"
[[ "$(getenforce)" == "Enforcing" ]] && echo "WARN: SELinux is enabled, auto login may fail"

echo "if can NOT login without pwd, please confirm permission of"
echo "$HOME:      should be 700 or 755"
echo "$HOME/.ssh: should be 600"
echo "Turn off SELinux: setenforce 0"

