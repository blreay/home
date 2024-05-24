#!/bin/bash

### 如何利用curl命令访问Kubernetes API server

#把证书设为环境变量。在设置时候请检查每一个参数
export clientcert=$(grep client-cert ~/.kube/config |cut -d" " -f 6)
#echo $clientcert

#将 client-key-data 保存为环境变量
export clientkey=$(grep client-key-data ~/.kube/config |cut -d" " -f 6)
#echo $clientkey

#然后是 certificate-authority-data
export certauth=$(grep certificate-authority-data ~/.kube/config |cut -d" " -f 6)
#echo $certauth

# 加密这些变量，供 curl 使用：
echo $clientcert | base64 -d > ./client.pem
echo $clientkey  | base64 -d > ./client-key.pem
echo $certauth   | base64 -d > ./ca.pem

#获取API URL：
export apiurl=$(kubectl config view | grep server  | awk '{print $2}')
#echo "apiurl=${apiurl}"

#使用 curl 和刚刚加密的密钥文件来访问 API server：
curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem ${apiurl}/version

