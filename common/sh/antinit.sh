#!/bin/bash

wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod 777 /bin/jq
yum install -y cvs vim zip lsof ksh git jq openssl expect

