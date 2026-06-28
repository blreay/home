---
name: wine-debug-gui
description: >
  Use when the user needs to debug a Windows GUI program on Linux — running PE binaries under Wine,
  setting up headless Xvfb display, driving the UI with xdotool, taking screenshots for verification,
  attaching gdb to Wine processes for source-level debugging of MinGW cross-compiled binaries.
  Also triggers for: "debug KiTTY on Linux", "run Windows exe headless", "wine + Xvfb setup",
  "gdb attach wine process", "test Windows build without Windows", "screenshot wine app",
  "automate GUI testing under wine", "cross-compile MinGW debug build".
  KiTTY (PuTTY fork) is the primary worked example throughout, but the patterns apply to any
  Windows GUI binary built with MinGW-w64.
---

# Wine + Xvfb 调试 Windows GUI 程序

在 Linux 上用 Wine 运行 Windows GUI 二进制，通过 Xvfb 虚拟显示 + xdotool 自动化 + gdb 源码级调试，全程无需 Windows 真机。

## 适用场景

- 要在 Linux 上跑 Windows `.exe` 并验证功能
- 要调试 Windows-only 的 bug（尤其 64-bit 特有的）
- 需要自动化 GUI 测试（截图 + OCR 验证）
- 需要用 gdb 对 MinGW 交叉编译的二进制做源码级调试

## 工作流程

5 个阶段，按顺序执行。每个阶段有明确的检查点，确认状态后再继续。

### Phase 1: 环境检查

**目标**：确认所有依赖可用，缺什么装什么。

检查清单：

```
wine (≥8.0)          — 跑 PE 二进制
Xvfb                 — 虚拟 X server（无头）
xdotool              — 模拟键盘鼠标
gdb                  — 调试 Wine 进程
puttygen (putty-tools) — 生成 .ppk 密钥（仅 SSH 场景需要）
imagemagick (import) — 从 Xvfb 截屏
tesseract-ocr        — 截图文字识别验证（可选，自动化测试用）
openssh-server       — 本机 sshd（仅 SSH 场景需要）
```

检查命令：

```bash
which wine && wine --version
which Xvfb && Xvfb -version 2>&1 | head -1
which xdotool && xdotool version 2>&1 | head -1
which gdb && gdb --version | head -1
which puttygen 2>/dev/null || echo "puttygen not found (optional)"
which import 2>/dev/null && import -version | head -1 || echo "imagemagick not found"
which tesseract 2>/dev/null || echo "tesseract not found (optional)"
```

**如果缺少**：Ubuntu/Debian:

```bash
sudo apt-get install -y wine wine64 xvfb xdotool gdb putty-tools imagemagick tesseract-ocr openssh-server
```

**检查 Xvfb 状态**：

```bash
# 是否已有 Xvfb 在跑
pgrep -f "Xvfb" && echo "Xvfb already running" || echo "Xvfb not running"
```

如果没有 Xvfb，后续 Phase 3 会启动。如果已有 Xvfb 但想用独立的 display，记下当前的 display number（避免冲突）。

**检查 sshd 状态**（如果测试需要 SSH 连接）：

```bash
ss -tlnp | grep :22 || echo "sshd not listening on port 22"
```

如果没监听：`sudo /usr/sbin/sshd -D -p 22 &` 或 `sudo systemctl start ssh`。

**检查 wine prefix**：

```bash
ls ~/.wine 2>/dev/null && echo "default prefix exists" || echo "no default prefix — will auto-init"
```

首次运行 wine 会自动初始化 prefix。如果需要分架构：
- 64-bit：`WINEPREFIX=~/wine_prefixes/wp64 WINEARCH=win64 wineboot -i`
- 32-bit：`WINEPREFIX=~/wine_prefixes/wp32 WINEARCH=win32 wineboot -i`

**Phase 1 完成条件**：wine、Xvfb、xdotool、gdb 四个关键工具就绪。如果缺失，先安装再继续。

---

### Phase 2: 准备二进制和密钥

**目标**：确认要调试的 `.exe` 存在，如果需要调试符号则确认有 debug build。

#### 2.1 确认二进制路径

```bash
# 用户指定的 exe 路径
ls -la <path-to-exe>
file <path-to-exe>  # 确认是 PE32+ (64-bit) 还是 PE32 (32-bit)
```

#### 2.2 判断是否需要 debug build

如果用户说"调试"、"gdb"、"看变量"、"打断点"——需要 debug build（带 `-g`，不带 `-s` strip）。

**MinGW 交叉编译 debug build 要点**：

1. CFLAGS 加 `-g`
2. LDFLAGS 去掉 `-s`（不要 strip）
3. **不要用 `-O0`**——很多项目的 `static` 函数跨 TU 引用在 `-O0` 时链接失败，被 `-O2` 的内联绕过。用 `-O2 -g` 是安全组合。
4. 确认 debug 信息在二进制里：

```bash
x86_64-w64-mingw32-objdump -h <exe> | grep debug
# 应看到 .debug_info / .debug_line / .debug_abbrev 等
```

5. 如果有 UPX 压缩步骤，用压缩**前**的副本（UPX 会破坏 DWARF），通常叫 `xxx_nocompress.exe`。

#### 2.3 SSH 密钥准备（仅需要 SSH 连接的场景）

```bash
# 生成 key（如已有则跳过）
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_kitty_test -N ""

# 加到 authorized_keys
cat ~/.ssh/id_ed25519_kitty_test.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 验证 OpenSSH 通路
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519_kitty_test -p 22 \
    "$(whoami)@localhost" "echo OK; uname -a"

# 转 .ppk（PuTTY/KiTTY 需要）
puttygen ~/.ssh/id_ed25519_kitty_test -o ~/.ssh/id_ed25519_kitty_test.ppk -O private
```

**Phase 2 完成条件**：二进制可执行，架构确认，debug 符号确认（如需要），SSH 密钥就绪（如需要）。

---

### Phase 3: 启动 Xvfb + Wine

**目标**：在虚拟 X 屏幕上启动 Windows GUI 程序。

#### 3.1 启动 Xvfb

```bash
# 挑一个空闲的 display number（默认 99）
Xvfb :99 -screen 0 1280x1024x24 > /tmp/xvfb_99.log 2>&1 &
sleep 2
ls /tmp/.X11-unix/X99  # 确认 socket 存在
```

后续所有 wine/xdotool 命令都要 `DISPLAY=:99`。

**display 号选择**：先 `pgrep -f Xvfb` 看已用的 display。如果有 Xvfb 跑在 `:100`，就用 `:99`。如果 `:99` 被占，递增到 `:101`。

#### 3.2 准备工作目录（可选）

如果程序需要 ini 配置文件、session 目录等：

```bash
mkdir -p /tmp/wine-test
# 创建最小化配置（以 KiTTY portable 模式为例）
cat > /tmp/wine-test/kitty.ini << 'EOF'
[KiTTY]
savemode=dir
configdir=/tmp/wine-test
EOF
mkdir -p "/tmp/wine-test/Sessions/Default Settings"
```

#### 3.3 启动程序

```bash
# 通用模板
WINEPREFIX=<prefix> DISPLAY=:<display> WINEDEBUG=-all \
    wine <exe-path> <args> \
    > /tmp/wine_out.log 2>&1 &

# 以 KiTTY 64-bit SSH 连接为例
WINEPREFIX=~/wine_prefixes/wp64 DISPLAY=:99 WINEDEBUG=-all \
    wine /path/to/kitty64.exe "$(whoami)@localhost" -P 22 \
    -i ~/.ssh/id_ed25519_kitty_test.ppk \
    > /tmp/wine_out.log 2>&1 &
```

**环境变量说明**：

| 变量 | 作用 |
|------|------|
| `WINEPREFIX` | Wine 配置目录，不同架构/项目隔离 |
| `DISPLAY` | 指向 Xvfb 的虚拟 display |
| `WINEDEBUG=-all` | 关闭 Wine 本体的调试输出（减少噪音） |

#### 3.4 验证进程存活

```bash
sleep 5
pgrep -f "$(basename <exe>)" && echo "Process running" || echo "Process died — check /tmp/wine_out.log"
```

如果进程死了，查看 `/tmp/wine_out.log` 排查原因。

#### 3.5 确认窗口存在

```bash
DISPLAY=:<display> xdotool search --name "" 2>/dev/null | while read wid; do
    NAME=$(xdotool getwindowname "$wid" 2>/dev/null)
    GEO=$(xdotool getwindowgeometry "$wid" 2>/dev/null | grep -oP 'Geometry.*')
    [ -n "$NAME" ] && echo "WID=$wid NAME='$NAME' $GEO"
done
```

**常见窗口名**：程序主窗口、安全确认弹窗（"PuTTY Security Alert"）、安装向导等。

#### 3.6 截图验证

```bash
DISPLAY=:<display> import -window root /tmp/screen.png
```

在 Read tool 支持的环境中可以直接 read 截图查看。

**Phase 3 完成条件**：进程存活，窗口可见，截图能看到预期 UI。

---

### Phase 4: 交互操作

**目标**：用 xdotool 模拟用户操作——点击按钮、输入文字、按键。

#### 4.1 找到目标窗口

```bash
# 按窗口名搜索
TARGET_WID=$(DISPLAY=:<display> xdotool search --name "<window-title>" 2>/dev/null | head -1)
```

#### 4.2 发送键盘输入

```bash
# 聚焦窗口
DISPLAY=:<display> xdotool windowfocus --sync "$TARGET_WID"
DISPLAY=:<display> xdotool windowraise "$TARGET_WID"

# 打字
DISPLAY=:<display> xdotool type --delay 50 --clearmodifiers "uname -srm"
DISPLAY=:<display> xdotool key Return

# 快捷键
DISPLAY=:<display> xdotool key alt+a        # Alt+A
DISPLAY=:<display> xdotool key ctrl+c       # Ctrl+C
DISPLAY=:<display> xdotool key Tab Return   # Tab then Enter
```

**注意**：`xdotool type` 不带尾随换行，用 `xdotool key Return` 单独发送。

#### 4.3 鼠标点击

```bash
# 绝对坐标点击
DISPLAY=:<display> xdotool mousemove 360 330 click 1

# 相对于窗口的点击
DISPLAY=:<display> xdotool mousemove --window "$TARGET_WID" 260 205 click 1
```

坐标从截图目测，通常需要调试几次才能命中。优先用键盘（`key`）替代鼠标点击——更可靠。

#### 4.4 处理弹窗

SSH host key 弹窗（PuTTY/KiTTY 场景）：

```bash
# 方法1：Alt+A 快捷键（Accept 按钮的加速键）
ALERT_WID=$(DISPLAY=:<display> xdotool search --name "PuTTY Security Alert" 2>/dev/null | head -1)
DISPLAY=:<display> xdotool key --window "$ALERT_WID" alt+a

# 方法2：Tab 导航到 Accept + Enter
DISPLAY=:<display> xdotool key --window "$ALERT_WID" Tab Tab Return
```

**验证弹窗关闭**：

```bash
DISPLAY=:<display> xdotool search --name "PuTTY Security Alert" 2>/dev/null | head -1
# 无输出 = 弹窗已关闭
```

#### 4.5 截图验证交互结果

每步操作后截图对比：

```bash
DISPLAY=:<display> import -window root /tmp/step-N.png
```

**Phase 4 完成条件**：目标操作全部执行，截图确认预期结果。

---

### Phase 5: GDB 源码级调试

**目标**：用 gdb attach 到 Wine 进程，对 MinGW 交叉编译的二进制做源码级调试。

#### 5.1 找到进程 PID

```bash
pgrep -f "<exe-basename>" | head -1
# 注意：可能有多个匹配，要找 wine 启动的那个（不是 wineserver64）
ps -ef | grep "<exe-basename>" | grep -v grep
```

#### 5.2 Attach gdb

```bash
gdb -p <PID>
```

如果报 `ptrace: Operation not permitted`：
- 容器环境：需要 `--cap-add SYS_PTRACE`
- 物理机/VM：`echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`

#### 5.3 加载调试符号

```bash
(gdb) file /path/to/<exe>_nocompress.exe   # 加载 DWARF 符号
```

#### 5.4 常用命令

```
# 浏览源码
(gdb) info functions <keyword>     # 列出匹配的函数
(gdb) info functions urlhack       # 例：找 URL 处理相关函数
(gdb) info functions winfb_        # 例：找 font fallback 相关函数

# 断点
(gdb) b <function_name>            # 函数断点
(gdb) b <file.c>:<line>            # 行断点
(gdb) b terminal.c:6896
(gdb) b winfont_fallback.c:382

# 运行
(gdb) c                            # continue
(gdb) bt                           # backtrace
(gdb) frame 3                      # 切换到第 3 帧
(gdb) info args                    # 函数参数
(gdb) info locals                  # 局部变量

# 查看内存
(gdb) print <variable>
(gdb) print urlhack_rx.re_nsub
(gdb) x/16wx <address>             # 16 words in hex
(gdb) x/64bx &urlhack_rx           # 64 bytes in hex

# 监视点
(gdb) watch <variable>             # 变量被修改时停下
(gdb) watch link_regions[0]->x0
```

#### 5.5 重要提示

- **KiTTY 的栈帧大多是 Windows GUI 回调**（`WindowProc` → ...），`bt` 会看到很多 wine 的 Windows API frame——focus 你的源代码 frame。
- **64-bit ABI 陷阱**：MinGW-w64 (Win64) 是 LLP64（`unsigned long = 4 bytes`），而 GNULIB 构建的 vendored 库可能是 LP64（`unsigned long = 8 bytes`）。如果 64-bit 有 bug 而 32-bit 没有，第一假设是 ABI 不匹配。用 `x/64bx &struct` 看原始字节，不要只看 `print` 的格式化输出。
- **winedbg 替代方案**：`WINEPREFIX=... DISPLAY=:99 winedbg <exe> <args>` 可以替代 gdb，但 winedbg 不识别 DWARF 调试符号，只能看到 Windows-style 函数名，功能远不如 gdb。**强烈推荐用 gdb**。

**Phase 5 完成条件**：gdb 成功 attach，能 `info functions` 看到源码级符号，能设断点并触发。

---

## 清理

```bash
pkill -f "<exe-basename>"   # 关程序
pkill wineserver            # 关 wine server
pkill -f "Xvfb :<display>"  # 关 Xvfb（如不再需要）
```

---

## 自动化测试方案

如果需要验证程序功能（非调试），可以结合截图 + OCR 做自动化验证：

```bash
# 1. 启动程序
# 2. 操作 UI
# 3. 截屏
DISPLAY=:99 import -window root /tmp/result.png
# 4. OCR 验证
OCR_TEXT=$(tesseract /tmp/result.png - 2>/dev/null)
for EXPECTED in "Linux" "hello" "expected-string"; do
    if echo "$OCR_TEXT" | grep -qi "$EXPECTED"; then
        echo "FOUND: $EXPECTED"
    else
        echo "MISSING: $EXPECTED"
    fi
done
```

---

## 故障排查

| 现象 | 处理 |
|------|------|
| `it looks like wine32 is missing` | 跑 64-bit 二进制时无害，忽略 |
| `winediag:ntlm_check_version ntlm_auth was not found` | 不影响非 NTLM 场景，忽略 |
| `wineserver64` 已存在、新启动报错 | `pkill wineserver` 后重试 |
| Xvfb 启动报 socket 权限错误 | `sudo mkdir -p /tmp/.X11-unix && sudo chmod 1777 /tmp/.X11-unix` |
| `import -window root` 截到全黑/全白 | 程序可能已退出，先 `pgrep` 确认进程存活 |
| gdb `ptrace: Operation not permitted` | `echo 0 \| sudo tee /proc/sys/kernel/yama/ptrace_scope` |
| 改了源码 build 后跑的仍是旧版 | `pkill -f exe-name; pkill wineserver` 确保没有缓存进程 |
| `-O0` 编译链接失败 | 用 `-O2 -g`，不要用 `-O0` |
| xdotool 键盘输入没反应 | 确认窗口聚焦后用 `--clearmodifiers`，先在窗口内点一下鼠标 |
| xpra 接管了 Xvfb 导致截图为空 | 截图时用 `-window root` 而不是 `-window <wid>`，或直接用纯 Xvfb 而非 xpra 管理的 display |

---

## 参考：KiTTY 具体示例

### 编译 debug build

```bash
# 在 MAKEFILE.MINGW 中:
# CFLAGS 加 -g, LDFLAGS 去掉 -s
./build.sh cross64
# 用 kitty64_nocompress.exe 调试
```

### 启动并测试

```bash
Xvfb :99 -screen 0 1280x1024x24 &
WINEPREFIX=~/wine_prefixes/wp64 DISPLAY=:99 WINEDEBUG=-all \
    wine /builds/kitty64_nocompress.exe \
    $(whoami)@localhost -P 22 -i ~/.ssh/id_ed25519_kitty_test.ppk &
```

### 复现 URL underline bleed

1. SSH 连接后，截屏看 Ubuntu MOTD 是否有 URL 下划线蔓延
2. 或在终端里输入 `echo http://w` 触发短链接
3. gdb 断点：`b urlhack_go_find_me_some_hyperlinks`、`b urlhack_add_link_region`
4. 检查 `link_regions[]` 是否被填充了大量重复条目

### 已知限制

- SMP 码点（emoji ≥ U+1F600）无法通过 Wine 的 `GetGlyphIndicesW` 探测 fallback font
- 某些 Windows-specific GDI 行为在 Wine 下可能更宽容，Wine 下不复现的 bug 可能需要真机 WinDbg 或 `valgrind` 辅助