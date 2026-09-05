#!/bin/bash
# install_agent_browser.sh
# 在被墙环境下安装 agent-browser + Chrome for Testing。
#
# 背景：`agent-browser install` 会去读 googlechromelabs.github.io 上的版本 JSON，
# 该域名在国内被墙（Connection reset），所以内置下载器必失败。本脚本绕开它：
# 手动从 npmmirror（阿里云，国内可达）下载 Chrome for Testing 二进制，
# 再用环境变量 AGENT_BROWSER_EXECUTABLE_PATH 指给 agent-browser。
#
# 用法：
#   ./install_agent_browser.sh [CFT_VERSION] [DEST_DIR]
# 默认：
#   CFT_VERSION=149.0.7827.115
#   DEST_DIR=$HOME/.local/chrome-for-testing
set -euo pipefail

CFT_VERSION="${1:-149.0.7827.115}"
DEST="${2:-$HOME/.local/chrome-for-testing}"
CHROME="$DEST/chrome-linux64/chrome"

echo "=== agent-browser 安装脚本（被墙环境绕行版）==="
echo "Chrome for Testing 版本: $CFT_VERSION"
echo "安装目录: $DEST"
echo

# ── 1. 全局安装 agent-browser ────────────────────────────────────────────
# Node 可能装在 root 名下（如 /root/.nvm），普通用户对全局目录无写权限 → EACCES。
# 用 sudo 时必须 env "PATH=$PATH" 把当前 PATH 传进去，否则 sudo 的精简 PATH 找不到 npm/node。
echo "[1/4] 全局安装 agent-browser ..."
if command -v agent-browser >/dev/null 2>&1; then
  echo "  已安装: $(agent-browser --version)"
else
  if [ -w "$(npm config get prefix)/lib/node_modules" ] 2>/dev/null; then
    npm install -g agent-browser
  else
    sudo env "PATH=$PATH" npm install -g agent-browser
  fi
  agent-browser --version
fi

# ── 2. 下载并解压 Chrome for Testing ─────────────────────────────────────
echo "[2/4] 下载 Chrome for Testing（约 177MB）..."
if [ -x "$CHROME" ]; then
  echo "  已存在: $CHROME"
else
  mkdir -p "$DEST"
  # -L 必须加：registry.npmmirror.com 会 302 重定向到 cdn.npmmirror.com，
  # 不跟随只会下到 111 字节的重定向提示页，解压报 "End-of-central-directory signature not found"。
  curl -fSL -o "$DEST/chrome-linux64.zip" \
    "https://registry.npmmirror.com/-/binary/chrome-for-testing/${CFT_VERSION}/linux64/chrome-linux64.zip"
  unzip -oq "$DEST/chrome-linux64.zip" -d "$DEST"
  test -x "$CHROME" || { echo "  解压失败：未找到 $CHROME"; exit 1; }
  echo "  解压完成: $CHROME"
fi

# ── 3. 检查共享库依赖 ────────────────────────────────────────────────────
echo "[3/4] 检查共享库依赖 ..."
MISSING="$(ldd "$CHROME" 2>/dev/null | grep 'not found' || true)"
if [ -n "$MISSING" ]; then
  echo "  缺失依赖："
  echo "$MISSING" | sed 's/^/    /'
  echo "  安装系统依赖 ..."

  # Ubuntu 23.10/24.04(noble)+ 做了 64-bit time_t 迁移，下面 4 个库改用 t64 后缀变体
  # （libasound2 → libasound2t64 等）。若仍按旧基名安装，noble 上会从 focal 源拉旧
  # 版并把 t64 变体连同一批 GUI 库（libgtk-3、libwebkit2gtk 等）降级移除。24.04+ 用
  # t64 名，旧版本/非 Ubuntu 用基名。其余库（libnss3、libdrm2 等）名未变。
  # 注意：VERSION_ID 形如 "24.04"，取主版本号比较；左侧 || 的失败被 set -e 豁免。
  APT_PKGS="libnss3 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2"
  USE_T64=0
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu) [ "${VERSION_ID%%.*}" -ge 24 ] 2>/dev/null && USE_T64=1 ;;
    esac
  fi
  if [ "$USE_T64" = 1 ]; then
    APT_PKGS="$APT_PKGS libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libasound2t64"
  else
    APT_PKGS="$APT_PKGS libatk1.0-0 libatk-bridge2.0-0 libcups2 libasound2"
  fi
  echo "  安装: $APT_PKGS"
  sudo apt-get update
  sudo apt-get install -y $APT_PKGS
else
  echo "  依赖齐全。"
fi

# ── 4. 持久化环境变量 ────────────────────────────────────────────────────
echo "[4/4] 持久化环境变量到 ~/.bashrc ..."
if grep -q "AGENT_BROWSER_EXECUTABLE_PATH" "$HOME/.bashrc" 2>/dev/null; then
  echo "  ~/.bashrc 已包含 AGENT_BROWSER_EXECUTABLE_PATH，跳过。"
else
  {
    echo ''
    echo '# agent-browser: Chrome for Testing（从 npmmirror 下载，google 版本 JSON 被墙）'
    echo "export AGENT_BROWSER_EXECUTABLE_PATH=$CHROME"
  } >> "$HOME/.bashrc"
  echo "  已追加到 ~/.bashrc"
fi

export AGENT_BROWSER_EXECUTABLE_PATH="$CHROME"

echo
echo "=== 安装完成 ==="
echo "浏览器路径: $CHROME"
echo "当前 shell 生效: export AGENT_BROWSER_EXECUTABLE_PATH=$CHROME"
echo "新开终端自动生效（已写入 ~/.bashrc）"
echo
echo "下一步：运行 verify_agent_browser.sh 验证安装。"
