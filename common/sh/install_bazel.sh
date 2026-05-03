#!/bin/bash

# 下载安装脚本
wget https://github.com/bazelbuild/bazel/releases/download/8.1.0/bazel-8.1.0-installer-linux-x86_64.sh
# 赋予执行权限
chmod +x bazel-8.1.0-installer-linux-x86_64.sh
# 运行安装（需要sudo）
sudo ./bazel-8.1.0-installer-linux-x86_64.sh
