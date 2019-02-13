#!/bin/bash

keyfile=${1?"please input key file"}
password=${2?"please input password"}

pemfile=${keyfile}.pem 
#openssl ec -in ${keyfile} -passin pass:${password} -passout pass:${password} -aes256 -out ${keyfile}.pem
openssl ec -in ${keyfile} -passin pass:${password} -out ${pemfile}
echo "Key:"
openssl ec -in ${pemfile} -inform PEM -text 2>/dev/null | awk '
	begin{start=0};
	/priv:/{start=1;next;}; 
	/pub:/{start=0};
	start==1 {print $1}
' | tr -d '\n:'

echo
