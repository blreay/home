---
name: windows-modern-standby-diagnose
description: 排查并修复 Windows 笔记本「盖盖子后不睡眠 / 发烫 / 电池被快速耗尽」问题。适用于现代待机(Modern Standby / S0 连接待机)机型——盖盖子后机器没有真正进入低功耗，持续发热掉电。本 skill 自动生成 powercfg 诊断报告(sleepstudy/diag/batteryreport)、解析报告定位拖住待机的元凶组件/进程(如音频总线、网卡、USB)、并提供一键修复(启用休眠 + 待机失败后自动转休眠的兜底)。当用户描述「盖上盖子没睡眠」「合盖后发烫」「待机掉电严重」「睡眠后耗电快」「Modern Standby 功耗高」等问题时使用。
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# Windows 现代待机发烫掉电排查与修复

## Overview

本 skill 用于诊断和修复 Windows 笔记本「盖盖子后未真正睡眠、发烫、电池快速耗尽」的问题。

典型现象：用户设置了"合盖即睡眠"，盖上盖子一两个小时后再打开，机器**烫手 + 电量大幅下降**。

根本背景：现代笔记本多采用 **S0 现代待机(Modern Standby / 连接待机)**，没有传统 S3 睡眠。S0 是一种"浅睡眠"，依赖软硬件配合才能降到深度低功耗(DRIPS)。任何一个后台程序、驱动或外设"赖着不睡"，整机就降不下去——表现就是盖着盖子持续发热掉电。常见元凶：**音频总线(Intel Smart Sound)**、网卡、USB 控制器、保活的 IM/会议/音乐 App。

本 skill 提供三个 bat 脚本(位于 `scripts/`)和一套报告解析方法。

---

## Workflow Decision Tree

按以下顺序执行：

1. **确认问题与环境** → 确认是"盖盖子发烫掉电"，确认 Windows 笔记本
2. **检查睡眠能力** → `powercfg /a`，判断是否 S0 现代待机机型
3. **生成诊断报告** → 运行 `collect_reports.bat`(sleepstudy + diag + batteryreport)
4. **解析报告定位元凶** → 解析 sleepstudy.html，找到低功耗占比低的会话 + Problem Device
5. **查占用音频的进程**(若元凶是音频) → 运行 `show_audio_processes.bat`
6. **应用修复** → 运行 `fix_lid_overheat.bat`(启用休眠 + 30 分钟兜底，AC 项可选)
7. **生成排查报告** → 输出 Markdown 报告，含证据、根因、解决方案
8. **验证** → 复跑 sleepstudy，确认低功耗占比回升 >90%

---

## 环境注意事项（重要）

- **运行 bat**：所有 bat 直接**双击**即可。需要管理员的脚本会自动弹一次 UAC。
- **bat 文件内容必须是纯 ASCII(英文)**：CMD 默认代码页(GBK)解析 UTF-8 中文会乱码，导致命令被拆散执行失败。本 skill 的 bat 已全部用英文。中文说明放在生成的 .md 报告里。
- **bat 提权检测用 `fltmc` 而非 `net session`**：`net session` 依赖 LanmanServer 服务，很多笔记本禁用了它，会导致"提权成功仍被判为非管理员"→ 反复弹 UAC 死循环。`fltmc` 不依赖服务。脚本还带 `__elevated__` 标记防循环。
- **在 Git Bash / cygwin 里手动跑 powercfg**：powercfg 不在 PATH，参数(如 `/a`)会被路径转换破坏。需：
  ```bash
  export MSYS_NO_PATHCONV=1
  PC="/c/Windows/System32/powercfg.exe"
  "$PC" /a
  ```
- **解析 html 报告**：用 PowerShell 提取表格文本：
  ```bash
  PS="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  "$PS" -NoProfile -Command "..."
  ```

---

## 步骤 1：确认问题与环境

确认用户描述的是"盖盖子后发烫/掉电/未睡眠"，且为 Windows 笔记本。询问大致时间段(几点盖、几点开、掉了多少电)，便于后续在报告里定位对应的待机会话。

## 步骤 2：检查睡眠能力

运行 `powercfg /a`，判断机型：

```bash
export MSYS_NO_PATHCONV=1
/c/Windows/System32/powercfg.exe /a
```

- 出现 **"待机 (S0 低电量待机)"** → 现代待机机型，本 skill 适用。
- 注意 **"休眠"** 在"有"还是"没有(尚未启用)"——若未启用，是没有兜底保护的关键隐患。

## 步骤 3：生成诊断报告

让用户**双击运行** `scripts/collect_reports.bat`(自动提权)。它会在**桌面**生成三份报告：

| 报告 | 内容 | 用途 |
|------|------|------|
| `sleepstudy.html` | 每次待机的低功耗占比、组件活跃排名、Problem Device 标记 | **定位元凶的核心** |
| `diag.html` | 系统睡眠时间线、各设备 D0/Dx 状态 | 辅助 |
| `batteryreport.html` | 每段待机掉电量(mWh/%)、电池健康度 | 量化掉电、算功耗 |

> 也可手动跑(管理员)：
> ```
> powercfg /sleepstudy /output "%USERPROFILE%\Desktop\sleepstudy.html"
> powercfg /systemsleepdiagnostics /output "%USERPROFILE%\Desktop\diag.html"
> powercfg /batteryreport /output "%USERPROFILE%\Desktop\batteryreport.html"
> ```

## 步骤 4：解析报告定位元凶 ⭐

读取桌面的 `sleepstudy.html`(用户机器上路径通常是 `C:\Users\<用户>\Desktop\sleepstudy.html`，cygwin 下为 `/c/Users/<用户>/Desktop/sleepstudy.html`)。

### 4.1 找到问题会话

用 PowerShell 提取所有待机会话行，找**低功耗占比(SW/HW)异常低**的那次(健康应 >90%，异常常 <50%)：

```bash
export MSYS_NO_PATHCONV=1
PS="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
"$PS" -NoProfile -Command "
\$h = Get-Content 'C:\Users\<用户>\Desktop\sleepstudy.html' -Raw
\$rows = [regex]::Matches(\$h, '<tr.*?</tr>', 'Singleline')
\$i=0
foreach (\$r in \$rows) {
  \$t = (\$r.Value -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '\s+',' ').Trim()
  if (\$t -match 'Sleep' -and \$t -match 'mWh') { 'IDX '+\$i+': '+\$t }
  \$i++
}
"
```

每行形如：
```
104 2026-06-16 21:28:00 1:52:21 Sleep 16,390 mWh 34% of battery 8,751 mW Drain SW: 30% HW: 30% 99%
```
判读：时长 1:52、掉 16,390 mWh/34%、平均 **8,751 mW(健康待机应 <500mW)**、**低功耗占比仅 30%** → 这次有问题。记下它的 IDX。

### 4.2 提取该会话的组件活跃排名(锁定元凶)

详情区在报告靠后，同样含该会话时间戳。提取其后约 180 行：

```bash
"$PS" -NoProfile -Command "
\$h = Get-Content 'C:\Users\<用户>\Desktop\sleepstudy.html' -Raw
\$rows = [regex]::Matches(\$h, '<tr.*?</tr>', 'Singleline')
\$all = @(); foreach (\$r in \$rows) { \$all += (\$r.Value -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '\s+',' ').Trim() }
\$idx = (0..(\$all.Count-1) | Where-Object { \$all[\$_] -match '21:28:00' -and \$all[\$_] -match '1:52:21' } | Select-Object -Last 1)
\$all[\$idx..(\$idx+180)] | Where-Object { \$_.Length -gt 1 }
"
```

在输出里找 **"NAME TYPE % ACTIVE TIME"** 表，活跃占比最高、并带 **`Problem Device: TRUE`** 的那一项就是元凶。例如：
```
英特尔® 智音技术总线 (HDAS)  Fx Device  69%  1:17:02   <- Problem Device: TRUE
PCI Express 根端口 (PEG0)    Fx Device   6%  0:06:57
```
→ 音频总线 69% 活跃且被标记为问题设备 = 元凶。

判读要点：
- **% LOW POWER STATE TIME (SW/HW)**：<90% 异常，越低越严重
- **DripsTransitions = 0**：整个待机从未进入深度低功耗
- **Problem Device: TRUE**：Windows 判定的问题设备
- **CHANGE RATE (mW)**：平均功耗，>1000mW 即不正常
- 常见元凶映射：音频总线/HDAS → 有 App 占用音频流未释放；网卡 → 虚拟网卡/保活；XHCI → 外接 USB 设备

### 4.3 (可选)量化掉电与电池健康

从 `batteryreport.html` 的 "Recent usage" 表提取进入/退出待机时的剩余 mWh，差值即掉电量；"FULL CHARGE CAPACITY / DESIGN CAPACITY" 之比是电池健康度。

## 步骤 5：查占用音频的进程（若元凶是音频）

让用户**双击运行** `scripts/show_audio_processes.bat`。它列出当前加载了 `audioses.dll`(音频会话模块)的进程，以及音频设备驱动状态。

> 常见占音频不放的 App：钉钉/Antding、Teams/Zoom/腾讯会议、音乐播放器、浏览器中正在播放或可自动播放媒体的标签页。
> 更直观：任务栏喇叭图标右键 → 打开音量合成器，看哪个 App 在出声。

## 步骤 6：应用修复

让用户**双击运行** `scripts/fix_lid_overheat.bat`(自动提权)。它会：
1. `powercfg /hibernate on` — 启用休眠
2. 设置**电池下待机 30 分钟后自动转休眠**(核心兜底，防止被烤干)
3. **可选**：询问是否同时设置 AC(接电源)60 分钟兜底——**默认 No**(直接回车即跳过)。因为 AC 的 HIBERNATEIDLE 被 Windows 默认隐藏，需先 `powercfg /attributes SUB_SLEEP HIBERNATEIDLE -ATTRIB_HIDE` 解除隐藏才能设置；且接电源在充电、无掉电风险，故可选。
4. 显示 `powercfg /a` 确认休眠已启用

修复原理：即使现代待机再次降不下去，电池下最多 30 分钟就转入**休眠(零功耗)**，从根上杜绝"盖着盖子被榨干"。

> 行为建议同时告知用户：盖盖子前退出/静音步骤 5 找到的元凶 App、拔掉外接 USB、到笔记本厂商官网更新对应驱动(如 Intel Smart Sound / 声卡 / 网卡 / BIOS)。

## 步骤 7：生成排查报告

用 Write 生成一份 Markdown 报告(建议放 `docs/troubleshooting/`)，包含：
- **结论先行(TL;DR)**：是 S0 现代待机未降功耗，元凶是 XXX
- **关键证据**：问题会话的时长/掉电/功耗/低功耗占比、组件活跃排名(含 Problem Device)、与正常会话对比
- **根因链条**：占用源 → 设备不休眠 → 整机不进 DRIPS → 发热掉电
- **解决方案**(按优先级)：兜底休眠 / 掐元凶 App / 更新驱动 / 改盖盖子动作
- **行动清单**和**命令速查手册**

参考模板见本 skill 自带的示例：
- `docs/example-report.md` — 完整排查报告样例(结论/证据/根因/解决方案/命令手册)
- `docs/example-sleepstudy-analysis.md` — sleepstudy 实锤分析样例(以音频总线为元凶的完整定位过程)

生成新报告时，建议直接参照这两份的结构与措辞填入本次的实测数据。

## 步骤 8：验证

让问题复现一次(盖盖子若干分钟)后复跑 `collect_reports.bat`，确认最新待机会话：
- 低功耗占比(SW/HW)回到 >90%
- 元凶不再是 Problem Device
- 或：即使待机仍异常，30 分钟兜底休眠已生效，电池不再被榨干(掉电 <5%)

---

## 命令速查（手动排查时用）

```powershell
:: A. 睡眠能力与状态
powercfg /a                          :: 支持的睡眠状态(S0/S3/休眠)
powercfg /lastwake                   :: 上次唤醒源
powercfg /requests                   :: 谁在阻止睡眠 [管理员]
powercfg /waketimers                 :: 唤醒定时器 [管理员]

:: B. 唤醒源
powercfg /devicequery wake_armed     :: 已武装唤醒的设备
powercfg /devicequery wake_from_any  :: 有唤醒能力的设备
powercfg /devicedisablewake "设备名"  :: 禁用某设备唤醒 [管理员]

:: C. 生成报告 [管理员]
powercfg /sleepstudy            /output "%USERPROFILE%\Desktop\sleepstudy.html"
powercfg /systemsleepdiagnostics /output "%USERPROFILE%\Desktop\diag.html"
powercfg /batteryreport         /output "%USERPROFILE%\Desktop\batteryreport.html"
powercfg /energy                /output "%USERPROFILE%\Desktop\energy.html"  :: 跑60秒综合诊断

:: D. 查占用音频的进程
powershell -NoProfile -Command "Get-Process | Where-Object {$_.Modules.ModuleName -contains 'audioses.dll'} | Select-Object ProcessName, Id"
::   或：任务栏喇叭右键 -> 音量合成器；或 resmon -> CPU -> 句柄搜 audio

:: E. 电源事件日志(待机时间线)
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).Date.AddHours(20); ProviderName='Microsoft-Windows-Kernel-Power'} | Sort-Object TimeCreated | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize -Wrap"
::   事件ID: 506=进入待机 507=退出待机 105=电源切换 172=待机网络 42=进入睡眠 107=恢复 41=异常断电

:: F. 修复 [管理员]
powercfg /hibernate on
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 1800   :: 电池30分钟兜底
powercfg /attributes SUB_SLEEP HIBERNATEIDLE -ATTRIB_HIDE               :: (可选)解除AC隐藏
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 3600   :: (可选)AC60分钟
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 2        :: 电池下合盖=休眠
powercfg /setactive SCHEME_CURRENT                                      :: 应用(改后必跑)
::   LIDACTION: 0=不操作 1=睡眠 2=休眠 3=关机

:: G. Git Bash/cygwin 写法
::   export MSYS_NO_PATHCONV=1; PC="/c/Windows/System32/powercfg.exe"; "$PC" /a
```

---

## 脚本清单

| 脚本 | 作用 | 权限 | 运行 |
|------|------|------|------|
| `scripts/collect_reports.bat` | 生成 sleepstudy + diag + batteryreport 到桌面 | 管理员(自动提权) | 双击 |
| `scripts/show_audio_processes.bat` | 列出占用音频的进程 + 音频驱动状态 | 普通 | 双击 |
| `scripts/fix_lid_overheat.bat` | 启用休眠 + 30分钟兜底(AC项可选,默认No) | 管理员(自动提权) | 双击 |

所有 bat 内容均为纯英文(避免 CMD 中文乱码)；提权用 `fltmc` 检测 + `__elevated__` 防循环标记。

## 示例报告(docs/)

| 文件 | 内容 |
|------|------|
| `docs/example-report.md` | 完整排查报告样例：结论先行 / 关键证据 / 根因 / 解决方案 / 行动清单 / 命令速查手册 |
| `docs/example-sleepstudy-analysis.md` | sleepstudy 实锤分析样例：以「音频总线 69% 活跃 + Problem Device」为元凶的完整定位过程 |

生成步骤 7 的报告时，直接参照这两份的结构填入本次实测数据即可。
