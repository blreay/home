#!/bin/bash
set -euo pipefail

echo "=== Ubuntu 24.04 原生 Firefox 安装脚本 ==="

# 1. 安装 add-apt-repository 所需的工具包
echo "[1/5] 安装 software-properties-common ..."
sudo apt install -y software-properties-common

# 2. 添加 Mozilla Team 官方 PPA
echo "[2/5] 添加 Mozilla Team PPA ..."
sudo add-apt-repository -y ppa:mozillateam/ppa

# 3. 移除 snap 占位包（如果存在）
if dpkg -l firefox 2>/dev/null | grep -q '1:1snap'; then
    echo "[3/5] 移除 snap 占位包 ..."
    sudo apt remove -y firefox
else
    echo "[3/5] 未检测到 snap 占位包，跳过"
fi

# 4. 从 PPA 安装原生 Firefox
echo "[4/5] 安装原生 Firefox ..."
sudo apt install -y -t 'o=LP-PPA-mozillateam' firefox

# 5. 验证
echo "[5/5] 验证安装 ..."
firefox --version

echo "=== 安装完成 ==="
