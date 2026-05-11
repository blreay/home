#!/bin/bash

# 下载安装脚本
file=bazel-8.1.0-installer-linux-x86_64.sh
url=https://github.com/bazelbuild/bazel/releases/download/8.1.0/$file
[[ -z $HTTP_RPOXY ]] && url=http://$MYVM:38080/tools/$file
wget $url
# 赋予执行权限
chmod +x $file
# 运行安装（需要sudo）
sudo ./$file
