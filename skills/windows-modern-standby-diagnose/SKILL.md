---
name: windows-modern-standby-diagnose
description: 排查并修复 Windows 笔记本「盖盖子后不睡眠 / 发烫 / 电池被快速耗尽」问题。适用于现代待机(Modern Standby / S0 连接待机)机型。涵盖两类根因：(A) 进了待机但降不到低功耗(音频总线/网卡/USB 等组件赖着不睡)；(B) 合盖后根本没进入待机(某程序如钉钉 tblive.exe 持有 execution/away 请求阻止睡眠)。本 skill 自动生成 powercfg 诊断报告(sleepstudy/diag/batteryreport)、用 sleepstudy 的 State 列与 powercfg /requests 区分两类问题并定位元凶组件/进程、并提供一键修复(启用休眠兜底 + 空闲超时强制睡眠 + 可选 requestsoverride 屏蔽程序请求)。当用户描述「盖上盖子没睡眠」「合盖后发烫」「待机掉电严重」「睡眠后耗电快」「Modern Standby 功耗高」「设置了休眠却没休眠」等问题时使用。
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# Windows 现代待机发烫掉电排查与修复

## Overview

本 skill 用于诊断和修复 Windows 笔记本「盖盖子后未真正睡眠、发烫、电池快速耗尽」的问题。

典型现象：用户设置了"合盖即睡眠"，盖上盖子一两个小时后再打开，机器**烫手 + 电量大幅下降**。

根本背景：现代笔记本多采用 **S0 现代待机(Modern Standby / 连接待机)**，没有传统 S3 睡眠。盖盖子发烫掉电有**两类根因**，必须先区分：

- **A 类：进了待机，但降不到低功耗**。S0 是"浅睡眠"，依赖软硬件配合才能降到深度低功耗(DRIPS)。某组件(**音频总线 Intel Smart Sound**、网卡、USB 控制器)赖着不进低功耗，整机降不下去。sleepstudy 里这次会话 **State = Sleep 但 SW/HW 低功耗占比 < 90%**。
- **B 类：合盖后根本没进入待机**。某程序持有 **execution / away 请求**(如钉钉直播插件 **tblive.exe**、会议/媒体软件)，强行阻止系统入睡。系统盖着盖子在 **Active 状态满载运行**。sleepstudy 里这次会话 **State = Active**(而非 Sleep)。
  - ⚠️ B 类时"待机后兜底休眠"**无法生效**——因为它的前提是"先进入待机"，而程序把这步堵死了。需要靠**空闲超时强制睡眠(STANDBYIDLE)**或 **requestsoverride** 来治。

还有一类**看似异常、实则健康**的现象，要会识别避免误判：

- **C 类(非故障)：没到休眠超时却提前休眠了**。用户设了"睡 N 小时才转休眠"，结果远不到 N 小时(如 8 小时)就发现休眠了，但**电量几乎没掉**(如 70%→71%)。这**不是问题**，是 S0 被"非用户原因"短暂唤醒后触发了**无人值守睡眠超时(UNATTENDSLEEP，默认仅 2 分钟)**，直接转入休眠省电——与用户设的 HIBERNATEIDLE(如 16 小时)是**两套独立计时**，互不相关。详见下方"关键机制"。

**区分方法**：看 sleepstudy 最新那次合盖会话的 **State 列**——`Active` = B 类(程序阻止)，`Sleep` 但低功耗占比低 = A 类(降不下去)。或用 `powercfg /requests` 当场看谁在阻止。提前休眠但电量没掉 = C 类(健康)。

本 skill 提供七个 bat 脚本(位于 `scripts/`)和一套报告解析方法。**排查前建议先读 `docs/FINDINGS-comprehensive-analysis.md`** —— 它汇总了全部 4 类机制、CONNECTIVITYINSTANDBY 真相和跨轮次方法论，能快速建立全局认识。

---

## 关键机制与术语（避免误判，必读）

- **`batteryreport` 里的 `Suspended` ≠ 休眠(Hibernate)**：`Suspended` 是电池报告对"低功耗状态"的统称，既可能是睡眠也可能是休眠，**不能据此判断进了休眠**。
- **如何确认"真的休眠了"**：看事件日志(System / Kernel-General)恢复时是否有**系统时钟大跳变同步**(如 `系统时间已从 X 更改为 Y`，跨度=睡眠时长)。休眠会完全断电、RTC 不连续 → 恢复时重设时钟；普通睡眠时钟连续，无此日志。另一旁证：`nhi: Driver exit RTD3`(设备深度断电)、`powercfg /a` 中休眠已启用。
- **无人值守睡眠超时(Unattended Sleep Timeout, GUID `7bc4a2f9-d8fc-4469-b07b-33eb785aaca0`)** ⭐：这是"提前休眠"的真凶，与 HIBERNATEIDLE 完全独立。触发条件**三者同时满足**：
  1. 系统当前已处于睡眠/S0 待机；
  2. 被一个**"非用户"源**唤醒——网络活动(Wi-Fi 自动重连最常见)、唤醒定时器(计划任务/Windows Update/维护)、USB/雷电/网卡等设备事件；**不是**键盘/鼠标/电源键/开盖(那些算"用户唤醒"，不触发)；
  3. 唤醒后在超时时间内(默认 **0x78=120 秒=2 分钟**)无真人操作。
  满足后系统**不回普通待机**，而是执行"无人值守动作"→ 进入睡眠并(若已启用休眠)很快转**休眠**。这就是"被网络唤醒一下 → 2 分钟后直接休眠 → 绕过 16 小时设置"的全过程。
  - 查看其值：`powercfg /attributes SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 -ATTRIB_HIDE`(先解除隐藏)后 `powercfg /q SCHEME_CURRENT SUB_SLEEP 7bc4a2f9-...`。
  - 想让"N 小时内保持睡眠不提前休眠"：把 UNATTENDSLEEP 也设成 N 小时。但**通常不建议**——提前休眠是健康省电行为，拉长它反而可能让被坏驱动打扰的夜晚退回 A 类发烫掉电。
- **判断提前休眠是否需要处理**：看进入/退出休眠时的**电量差**。几乎不掉(如 70%→71%) = 健康(C 类)，无需处理，仅向用户解释；若伴随大量掉电/发烫，才回到 A/B 类排查。
- **"网络唤醒"有两种，禁用网卡唤醒只关掉其中一种** ⭐(高频混淆点)：用户常说"我已经禁用网络唤醒了，为什么睡眠还被网络唤醒？"——因为这是两个不同机制：
  1. **Wake-on-LAN(网络唤醒 / 魔术包 / 模式匹配)**：**外部设备**发特定网络包，把睡死的电脑**从外部叫醒**。由"允许此设备唤醒计算机" / `WakeOnMagicPacket` / `WakeOnPattern` / `wake_armed` 控制。`disable_nic_wake.bat` 关的就是这个，**确实有效**。
  2. **S0 连接待机的"网络保活"(系统自我上线)**：S0 现代待机**在睡眠中由系统自己周期性地短暂让网卡上线**，维持 Wi-Fi、收推送、跑后台维护——这是 **S0 设计行为，不是外部唤醒**。事件日志特征：`Connectivity state in standby: Connected, Reason: None` + `exiting connected standby`(**Reason: None = 无外部唤醒源，是系统主动**)。
  - **关键**：禁用 Wake-on-LAN **管不到第 2 种**。第 2 种由 `CONNECTIVITYINSTANDBY`(待机网络连接性)控制，而该设置在企业机器上**常被安全软件锁死**(`Access denied`，见上文)。所以"睡眠中被网络激活 → 触发无人值守超时 → 提前休眠"这条链，**靠禁用网卡唤醒堵不住**。
  - **唯一可靠的根治**：**物理断网(睡前开飞行模式 / 关 Wi-Fi)**。网卡物理关闭后 S0 无法自我上线，从源头断绝。这也是为什么飞行模式是绕过"安全软件锁 + S0 设计行为"的终极手段。

---

## Workflow Decision Tree

按以下顺序执行：

1. **确认问题与环境** → 确认是"盖盖子发烫掉电"，确认 Windows 笔记本
2. **检查睡眠能力** → `powercfg /a`，判断是否 S0 现代待机机型
3. **生成诊断报告** → 运行 `collect_reports.bat`(sleepstudy + diag + batteryreport)
4. **先分诊 A / B / C 类** ⭐ → 先看**电量是否大幅下降**：
   - **电量几乎没掉(如 70%→71%)但用户觉得"提前休眠了"** → **C 类(健康，非故障)**：用事件日志时钟跳变确认是真休眠 + 解释无人值守超时机制(见"关键机制")，**无需修复**，仅向用户解释。
   - **电量大幅下降 + 发烫** → 看 sleepstudy 最新合盖会话的 **State 列**：
     - **State = Active**（合盖却满载运行）→ **B 类：程序阻止入睡** → 转步骤 5B
     - **State = Sleep 但 SW/HW < 90%**（睡了没睡熟）→ **A 类：降不到低功耗** → 转步骤 5A
5A. **(A类) 定位元凶组件 + 查音频进程** → sleepstudy 组件活跃排名 + `show_audio_processes.bat`
5B. **(B类) 抓阻止睡眠的进程** → `show_sleep_blockers.bat`(`powercfg /requests`) + sleepstudy 该 Active 会话的进程 CPU 排名
6. **应用修复**：
   - A 类 → `fix_lid_overheat.bat`(启用休眠 + 待机后 30 分钟兜底)
   - B 类 → `set_force_sleep.bat`(空闲超时强制睡眠，可选 requestsoverride 屏蔽程序) + 退出元凶程序
   - C 类 → 无需修复；若用户坚持"N 小时内不提前休眠"，可拉长 UNATTENDSLEEP(见命令速查 F3，但通常不建议)
   - A/B 两类都建议同时装上，互为补充
7. **生成排查报告** → 输出 Markdown 报告，含证据、根因(注明 A/B/C 类)、解决方案
8. **验证** → 复跑 sleepstudy，确认最新会话 State=Sleep 且低功耗占比 >90%(C 类无需此步)

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
- **`powercfg /setdcvalueindex` 报 `Access is denied` 时改用 `/change`** ⭐：在 IT 管控/企业锁定的机器上(如蚂蚁公司电脑，有 AspectService 等管控软件)，`powercfg /setdcvalueindex` / `/setacvalueindex` 直接写设置索引会被拒(`Access is denied`，errorlevel=5)，即使已是管理员。但标准超时接口 **`powercfg /change`** 仍然有效。所以设置睡眠/休眠超时**优先用 `/change`**：
  ```
  powercfg /change standby-timeout-dc 10      :: 电池10分钟进睡眠
  powercfg /change hibernate-timeout-dc 960   :: 电池睡16小时(960分)后转休眠
  ```
  `/change` 的单位是**分钟**(不是秒)。验证时 16h=960min=57600s=0x0000e100。注意 `/change` 没有覆盖"待机网络连接性""唤醒定时器"等设置的别名——这些要靠下面的"可见窗口放行"或改驱动层(见 `disable_nic_wake.bat`)。
- **`CONNECTIVITYINSTANDBY`(待机网络连接性)的 `Access is denied` 不是"锁死"，而是安全软件实时拦截，可被用户放行** ⭐(经实测修正)：早先以为它被企业彻底锁死无解，**是错的**。真相：
  - **不是组策略硬锁**——GPO 注册表项(`HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings\...`)查不到，证明无 GPO 锁。
  - 真相是 **AspectService 这类安全软件对"修改电源/睡眠设置"做实时拦截并弹窗**：后台/隐藏窗口跑 → 弹窗看不到 → 默认拒绝 → `Access is denied`；**可见窗口 + 用户手动点"允许"** → 放行 → **设置成功**。
  - 实测：可见窗口下 `powercfg /setdcvalueindex SCHEME_CURRENT SUB_NONE CONNECTIVITYINSTANDBY 0` 成功把电池侧改为"禁用"(0x0)；同一会话里 AC 侧偶尔仍被拒，是因为那一下没弹/没点允许，**重试并确保点允许即可**。
  - **方法论**：在受安全软件管控的机器上改电源设置，**一律用可见窗口提权 + 逐条执行 + 让用户盯着弹窗点允许**；某条被拒就单独重试那一条，不要因一次 `Access is denied` 就断定"无解"。
  - 兜底/替代(若用户不想反复点允许)：①禁用网卡唤醒(`disable_nic_wake.bat`)②睡前飞行模式。
  > 关键认知：**S0 现代待机设计上默认会周期性自我联网**(连接待机的"连接"即指此)。`CONNECTIVITYINSTANDBY=禁用` 正是关掉这个"自我联网保活"的总开关，能从源头消除"自我上线→触发无人值守超时→提前休眠"的链条，并更省电。耗电终极兜底仍是"关键电量动作=休眠"(`SUB_BATTERY BATACTIONCRIT`=2)。
- **后台 `-WindowStyle Hidden` 提权运行会吞掉安全软件弹窗** ⭐：隐藏窗口时，企业安全软件的授权弹窗用户看不到、无法点"允许"，命令直接返回 `Access is denied`。**涉及可能触发安全软件的特权命令(改电源设置、写注册表等)，必须用可见窗口提权**(`Start-Process -Verb RunAs`，**不加** `-WindowStyle Hidden`)，并提示用户盯着屏幕点允许。这是本 skill 多次 `Access denied` 的真正原因。
- **解析报告**：用 PowerShell 提取表格文本：
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

## 步骤 4：判定 A 类还是 B 类 ⭐（关键分诊）

读取桌面的 `sleepstudy.html`(路径通常 `C:\Users\<用户>\Desktop\sleepstudy.html`，cygwin 下 `/c/Users/<用户>/Desktop/sleepstudy.html`)。先提取**最新的合盖会话**，看它的 **State 列**：

```bash
export MSYS_NO_PATHCONV=1
PS="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
"$PS" -NoProfile -Command "
\$h = Get-Content 'C:\Users\<用户>\Desktop\sleepstudy.html' -Raw
\$rows = [regex]::Matches(\$h, '<tr.*?</tr>', 'Singleline')
\$i=0
foreach (\$r in \$rows) {
  \$t = (\$r.Value -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '\s+',' ').Trim()
  if ((\$t -match 'Active' -or \$t -match 'Sleep') -and \$t -match 'mWh') { 'IDX '+\$i+': '+\$t }
  \$i++
}
"
```

对照问题时段那次会话：

- 行里是 **`Active` + 大量 mWh/% drain**（如 `21:05:35 1:49:22 Active 27,120 mWh 56% 14,878 mW Drain`）
  → **B 类：程序阻止了入睡**（合盖却满载运行）→ **转步骤 5B**
- 行里是 **`Sleep`，但带 `SW: xx% HW: xx%` 且占比 < 90%**（如 `21:28:00 1:52:21 Sleep ... SW: 30% HW: 30%`）
  → **A 类：进了待机但降不到低功耗** → **转步骤 5A**

> 也可直接 `powercfg /requests`(管理员)当场看：`SYSTEM`/`执行` 栏非空 = 有程序阻止睡眠(B 类)。

---

## 步骤 5A：(A 类) 定位拖住待机的组件 + 查音频进程

读取桌面的 `sleepstudy.html`。

### 5A.1 找到问题会话

承步骤 4 已找到的 Sleep 会话（低功耗占比 SW/HW < 90%）。形如：
```
104 2026-06-16 21:28:00 1:52:21 Sleep 16,390 mWh 34% of battery 8,751 mW Drain SW: 30% HW: 30% 99%
```
判读：平均 **8,751 mW(健康待机应 <500mW)**、**低功耗占比仅 30%** → 有问题。记下 IDX。

### 5A.2 提取该会话的组件活跃排名(锁定元凶)

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

### 5A.3 若元凶是音频 → 查占用音频的进程

让用户**双击运行** `scripts/show_audio_processes.bat`，列出当前加载 `audioses.dll` 的进程及音频驱动状态。常见占音频不放的 App：钉钉/Antding、Teams/Zoom/腾讯会议、音乐播放器、浏览器媒体标签。

### 5A.4 (可选)量化掉电与电池健康

从 `batteryreport.html` 的 "Recent usage" 表提取进入/退出待机时的剩余 mWh，差值即掉电量；"FULL CHARGE CAPACITY / DESIGN CAPACITY" 之比是电池健康度。

---

## 步骤 5B：(B 类) 抓住阻止睡眠的进程

### 5B.1 当场抓（若问题正在发生 / 程序还在跑）

让用户**双击运行** `scripts/show_sleep_blockers.bat`（= `powercfg /requests`，自动提权）。看输出里的 **`SYSTEM` / `执行(EXECUTION)` / `DISPLAY` / `AWAYMODE`** 各栏——非空栏里列出的进程/驱动就是正在阻止睡眠的元凶。

> 注意：若元凶程序已经退出（如用户已重新打开电脑、直播已停），`/requests` 会显示"无"。这时改用事后法（5B.2）。

### 5B.2 事后查（从 sleepstudy 的 Active 会话查进程 CPU 排名）

提取那次 `Active` 会话的进程占用排名（其后约 90 行的进程表，第一列是占用计数）：

```bash
"$PS" -NoProfile -Command "
\$h = Get-Content 'C:\Users\<用户>\Desktop\sleepstudy.html' -Raw
\$rows = [regex]::Matches(\$h, '<tr.*?</tr>', 'Singleline')
\$all = @(); foreach (\$r in \$rows) { \$all += (\$r.Value -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '\s+',' ').Trim() }
\$idx = (0..(\$all.Count-1) | Where-Object { \$all[\$_] -match '21:05:35' -and \$all[\$_] -match 'Active' } | Select-Object -Last 1)
\$all[\$idx..(\$idx+60)] | Where-Object { \$_.Length -gt 1 }
"
```

占用计数最高、断崖式领先的那个进程就是元凶。实例：
```
\Device\...\Antding\...\plugins\tblive\bin\64bit\tblive.exe [楚一] 2100 ...   <- 钉钉直播插件，元凶
Microsoft.LockApp (锁屏)                                       1668 ...
```
→ `tblive.exe` 占用 2100 断崖第一 = 元凶。常见 B 类元凶：钉钉直播插件 tblive.exe、会议软件、媒体播放器、下载器、某些后台同步进程。

---

## 步骤 6：应用修复

根据 A/B 类选择对应脚本；**推荐两类修复都装上，互为补充**(兜底休眠挡"睡不熟"，强制睡眠挡"不让睡")。

### 6A：A 类修复 — 启用休眠 + 待机后兜底转休眠

让用户**双击运行** `scripts/fix_lid_overheat.bat`(自动提权)。它会：
1. `powercfg /hibernate on` — 启用休眠
2. 设置**电池下待机 30 分钟后自动转休眠**(核心兜底)
3. **可选**：询问是否同时设置 AC 60 分钟兜底——**默认 No**(回车跳过)。AC 的 HIBERNATEIDLE 被 Windows 默认隐藏，脚本会先 `powercfg /attributes SUB_SLEEP HIBERNATEIDLE -ATTRIB_HIDE` 解除隐藏；接电源在充电、无掉电风险，故可选。
4. 显示 `powercfg /a` 确认休眠已启用

原理：即使待机降不下去，电池下最多 30 分钟转入休眠(零功耗)。

### 6B：B 类修复 — 空闲超时强制睡眠 + 禁用网卡唤醒 + 屏蔽程序请求

**(1) 空闲超时强制睡眠**——让用户**双击运行** `scripts/set_force_sleep.bat`(自动提权)。它用可靠的 `/change` 接口设置：
1. **STANDBYIDLE**：电池 10 分钟、AC 30 分钟**空闲即进睡眠**——**不受程序 execution/away 请求影响**，是治 B 类的关键。
2. **HIBERNATEIDLE**：睡 16 小时后转休眠(`/change hibernate-timeout-dc 960`)——满足"合盖长时间保持睡眠、超时才休眠"的需求。
3. **可选**(默认 No)：对反复阻止睡眠的进程加 `requestsoverride`，输入进程名(如 `tblive.exe`)后永久屏蔽其唤醒请求。

> ⚠️ 脚本一律先用 `powercfg /change`(单位分钟)而非 `/setdcvalueindex`(单位秒)——后者在锁定机器上会 `Access is denied`。详见"环境注意事项"。

**(2) 禁用网卡唤醒(减少网络驱动的待机耗电)**——让用户**双击运行** `scripts/disable_nic_wake.bat`(自动提权)。它对所有物理网卡禁用 Wake-on-Magic-Packet / Wake-on-Pattern-Match，并解除所有 wake_armed 设备的唤醒。

> 设备管理器手动等价操作：网卡 → 属性 → "高级"标签把"唤醒模式匹配(Wake on Pattern Match)""魔术包(Wake on Magic Packet)"设为 **Disabled**；"电源管理"标签取消"允许此设备唤醒计算机"(若有)、保留"允许关闭此设备以省电"。

**(3) 关于"彻底避免音频/网络激活"的真相**：S0 现代待机**设计上无法 100% 保证**睡眠期间音频/网络零激活零耗电(连接待机的"连接"即指允许网络活动)。软件层只能大幅降低风险，不能根除。最可靠的兜底是**关键电量动作=休眠**(`SUB_BATTERY BATACTIONCRIT`，多数机器默认就是 2=休眠)——即使睡眠期间被异常耗电，电量见底前也会强制休眠，不会被烤干或丢数据。最彻底的断网手段是**睡前开飞行模式 / 关 Wi-Fi**。

> ⚠️ 关键认知：B 类时 6A 的"待机后兜底休眠"**救不了场**，因为程序把"进入待机"这步堵死了，兜底链条不触发。必须用 6B 的空闲超时(STANDBYIDLE)从"进入待机"之前就强制。

### 行为建议(两类通用)

告知用户：盖盖子前退出元凶程序(A 类的占音频 App / B 类的 tblive 等，**托盘右键彻底退出**而非只关窗口)、拔掉外接 USB、到笔记本厂商官网更新对应驱动(Intel Smart Sound / 声卡 / 网卡 / BIOS)。

## 步骤 7：生成排查报告

用 Write 生成一份 Markdown 报告(建议放 `docs/troubleshooting/`)，包含：
- **结论先行(TL;DR)**：注明是 **A 类(进了待机没睡熟)还是 B 类(根本没进待机)**，元凶是 XXX
- **关键证据**：
  - A 类：问题会话的时长/掉电/功耗/低功耗占比、组件活跃排名(含 Problem Device)、与正常会话对比
  - B 类：sleepstudy 那次会话 State=Active 的事实、进程 CPU 排名(元凶进程)、`/requests` 截图、与正常合盖会话(State=Sleep)对比
- **根因链条**：
  - A 类：占用源 → 设备不进低功耗 → 整机不进 DRIPS → 发热掉电
  - B 类：程序持 execution 请求 → 合盖不进待机 → Active 满载 → 发热掉电(兜底休眠因未进待机而无法触发)
- **解决方案**(按优先级) 和 **行动清单**、**命令速查手册**

参考模板见本 skill 自带的示例：
- `docs/example-report.md` — A 类完整排查报告样例
- `docs/example-sleepstudy-analysis.md` — A 类 sleepstudy 实锤分析样例(音频总线元凶)
- `docs/example-report-B-blocker.md` — B 类排查报告样例(钉钉 tblive.exe 阻止睡眠)
- `docs/example-report-C-early-hibernate.md` — C 类报告样例(8 小时提前休眠、实为健康省电、无人值守超时机制)

生成新报告时，参照对应类别的样例结构填入本次实测数据。

## 步骤 8：验证

让问题复现一次(盖盖子若干分钟)后复跑 `collect_reports.bat`，确认最新会话：
- **State = Sleep**(B 类重点：确认不再是 Active)
- **低功耗占比(SW/HW) >90%**(A 类重点)、元凶不再是 Problem Device
- 或：即使仍异常，兜底休眠/强制睡眠已生效，电池不再被榨干(掉电 <5%)

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

:: F. A类修复(进了待机没睡熟) [管理员]
powercfg /hibernate on
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 1800   :: 电池待机30分钟后兜底休眠
powercfg /attributes SUB_SLEEP HIBERNATEIDLE -ATTRIB_HIDE               :: (可选)解除AC隐藏
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 3600   :: (可选)AC60分钟
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 2        :: 电池下合盖=休眠
powercfg /setactive SCHEME_CURRENT                                      :: 应用(改后必跑)
::   LIDACTION: 0=不操作 1=睡眠 2=休眠 3=关机

:: F2. B类修复(程序阻止入睡 / 减少待机耗电) [管理员]
powercfg /requests                                                     :: 当场抓谁在阻止睡眠(SYSTEM/执行栏)
:: 用 /change 设超时(锁定机器上 setvalueindex 会 Access denied; /change 单位=分钟)
powercfg /change standby-timeout-dc 10                                 :: 电池10分钟空闲进睡眠
powercfg /change standby-timeout-ac 30                                 :: AC30分钟
powercfg /change hibernate-timeout-dc 960                              :: 电池睡16小时(960分)后转休眠
powercfg /change hibernate-timeout-ac 960
powercfg /requestsoverride PROCESS tblive.exe SYSTEM EXECUTION DISPLAY AWAYMODE  :: 永久屏蔽某进程唤醒请求
powercfg /requestsoverride                                             :: 查看已有覆盖
:: 关闭"待机自我联网保活"总开关(从源头消除提前休眠诱因) —— 必须可见窗口提权+点允许
powercfg /attributes SUB_NONE f15576e8-98b7-4186-b944-eafa664402d9 -ATTRIB_HIDE     :: 先解除隐藏
powercfg /setdcvalueindex SCHEME_CURRENT SUB_NONE f15576e8-98b7-4186-b944-eafa664402d9 0  :: 电池禁用(实测可成功)
powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE f15576e8-98b7-4186-b944-eafa664402d9 0  :: AC禁用(被拒就重试+点允许)
:: 禁用网卡唤醒(减少网络驱动的待机耗电)
powershell -Command "Get-NetAdapter -Physical | ForEach-Object { Disable-NetAdapterPowerManagement -Name $_.Name -WakeOnMagicPacket -WakeOnPattern }"
for /f "delims=" %D in ('powercfg /devicequery wake_armed') do powercfg /devicedisablewake "%D"
powercfg /setactive SCHEME_CURRENT
::   注1：CONNECTIVITYINSTANDBY 的 Access denied 不是锁死, 是安全软件实时拦截 → 可见窗口+手动点允许即可成功
::        (后台 -WindowStyle Hidden 会吞弹窗导致必拒)；被拒就单独重试那一条
::   注2：关键电量动作=休眠 是耗电兜底(powercfg /q SCHEME_CURRENT SUB_BATTERY BATACTIONCRIT, 2=休眠)
::   注3：最彻底断网：睡前开飞行模式 / 关 Wi-Fi。

:: F3. C类(提前休眠)诊断与可选调整 [管理员]
::   判断是否真休眠: 看恢复时事件日志有无时钟大跳变
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-General'} -MaxEvents 20 | Where-Object {$_.Message -match '系统时间已从|time.*changed'} | Select TimeCreated,@{N='M';E={($_.Message -split [char]10)[0]}}"
::   查无人值守睡眠超时(默认0x78=120秒); 它被网络/定时器等"非用户"唤醒后触发, 与HIBERNATEIDLE独立
powercfg /attributes SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 -ATTRIB_HIDE   :: 先解除隐藏
powercfg /q SCHEME_CURRENT SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0          :: 看当前值
::   (可选,通常不建议)把无人值守超时也拉到16小时, 让N小时内不提前休眠:
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 57600
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 57600
powercfg /setactive SCHEME_CURRENT
::   注：提前休眠若电量几乎不掉(如70%→71%)是健康省电, 一般无需调整, 仅向用户解释即可。

:: G. Git Bash/cygwin 写法
::   export MSYS_NO_PATHCONV=1; PC="/c/Windows/System32/powercfg.exe"; "$PC" /a
```

---

## 脚本清单

| 脚本 | 作用 | 类别 | 权限 | 运行 |
|------|------|------|------|------|
| `scripts/collect_reports.bat` | 生成 sleepstudy + diag + batteryreport 到桌面 | 通用 | 管理员(自动提权) | 双击 |
| `scripts/show_audio_processes.bat` | 列出占用音频的进程 + 音频驱动状态 | A 类 | 普通 | 双击 |
| `scripts/show_sleep_blockers.bat` | `powercfg /requests` 抓正在阻止睡眠的进程/驱动 | B 类 | 管理员(自动提权) | 双击 |
| `scripts/fix_lid_overheat.bat` | 启用休眠 + 待机后30分钟兜底(AC项可选,默认No) | A 类修复 | 管理员(自动提权) | 双击 |
| `scripts/set_force_sleep.bat` | 空闲10/30分进睡眠 + 睡16小时转休眠(均用 /change 可靠设置)+ 可选 requestsoverride | A+B 类修复 | 管理员(自动提权) | 双击 |
| `scripts/disable_nic_wake.bat` | 禁用网卡的魔术包/模式匹配唤醒 + 解除 wake_armed 设备 | B 类/省电 | 管理员(自动提权) | 双击 |
| `scripts/disable_standby_network.bat` | 关闭"待机自我联网"(CONNECTIVITYINSTANDBY=禁用)，从源头消除自我唤醒→提前休眠链；**可见窗口**+被拒自动重试，需手动点安全软件"允许" | B/C 类/省电 | 管理员(自动提权,可见窗口) | 双击 |

所有 bat 内容均为纯英文(避免 CMD 中文乱码)；提权用 `fltmc` 检测 + `__elevated__` 防循环标记。其中 `disable_standby_network.bat` **故意不隐藏窗口**，以便用户看到并批准安全软件的拦截弹窗。

## 示例报告 / 知识库(docs/)

| 文件 | 内容 |
|------|------|
| **`docs/FINDINGS-comprehensive-analysis.md`** | ⭐ **综合分析报告(必读)**：汇总全部 4 类机制(A/B/C + 网络唤醒澄清)、CONNECTIVITYINSTANDBY 真相、跨轮次方法论与踩坑、本机最终稳态配置。排查前先读这份建立全局认识。 |
| `docs/example-report.md` | A 类完整排查报告样例：结论先行 / 关键证据 / 根因 / 解决方案 / 行动清单 / 命令速查手册 |
| `docs/example-sleepstudy-analysis.md` | A 类 sleepstudy 实锤分析样例：以「音频总线 69% 活跃 + Problem Device」为元凶的完整定位过程 |
| `docs/example-report-B-blocker.md` | B 类排查报告样例：合盖后 State=Active、钉钉 tblive.exe 阻止入睡的完整定位与修复 |
| `docs/example-report-C-early-hibernate.md` | C 类报告样例：8 小时提前休眠(非故障)，时钟跳变证明真休眠、无人值守超时(2分钟)机制、电量零损耗 |

生成步骤 7 的报告时，参照对应类别(A/B/C)的样例结构填入本次实测数据即可；方法论与全局背景见 `FINDINGS-comprehensive-analysis.md`。
