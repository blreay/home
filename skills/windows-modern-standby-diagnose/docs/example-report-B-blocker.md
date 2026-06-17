# 第二次发烫排查：合盖后系统未进入睡眠（钉钉直播插件作祟）

> 生成时间：2026-06-17 23:42
> 现象：21:10 左右合盖，22:30 取出时机身极烫、电量几乎耗尽
> 与前次的区别：**这次不是"待机降不下去"，而是"合盖根本没进入睡眠"**

---

## 一、结论先行（TL;DR）

**今晚机身发烫、电池耗尽的原因：钉钉的直播插件 `tblive.exe` 在后台高强度运行，持有了"执行请求(Execution Request)"，强行阻止了系统进入睡眠。**

- 你 21:05 合盖后，系统**没有进入待机**，而是带着满载的 `tblive.exe` 在 **Active(完全清醒)状态持续运行了 1 小时 49 分**，平均功耗 **14.9W**，掉电 **56%**。
- 直到约 22:54，`tblive.exe` 退出，系统才得以进入待机；随后**休眠兜底正常生效**，30 分钟后(23:25)转入了 Suspended 休眠。
- **"按设置应该会休眠却没休眠"的原因**：休眠兜底的前提是"先进入待机"。`tblive.exe` 把"进入待机"这一步直接堵死了，兜底链条根本没机会启动。

> 一句话：上次是"睡了但没睡熟"，这次是"被一个程序拽着根本没让睡"。

---

## 二、决定性证据

### 1. sleepstudy 记录（今晚那段被记为 Active，不是 Sleep）

```
157  2026-06-17 21:05:35  时长 1:49:22  Active  27,120 mWh  56% of battery  14,878 mW  Drain
```

- 状态是 **Active**（完全清醒），不是 Sleep。
- 功耗 **14,878 mW（≈14.9W）**，比上次发烫那次(8.7W)更猛——等于盖着盖子在满载干活。
- 这一整段 1:49:22 期间，合盖**没有触发任何 `Transition To Sleep`**。

对比同一天早些时候的正常合盖（都正常入睡）：
```
150  18:58:16  Sleep   Entry: Transition To Sleep   Exit: Lid       ✅ 正常
153  18:58:37  0:48:09 Sleep  SW: 95% HW: 95%                       ✅ 正常
156  20:36:17  0:09:17 Sleep  Entry: Transition To Sleep            ✅ 正常
157  21:05:35  1:49:22 Active  ← 唯独这次合盖没入睡                  ❌ 异常
```

### 2. 进程 CPU 占用排名（锁定元凶）

21:05~22:54 这段 Active 期间，CPU 占用排名：

| 排名 | 进程 | 占用计数 | 身份 |
|------|------|----------|------|
| 🥇 **1** | **`Antding\...\plugins\tblive\bin\64bit\tblive.exe`** | **2100** | **钉钉「直播(tblive)」插件** |
| 2 | `Microsoft.LockApp`（锁屏界面） | 1668 | 被前者带着空转 |
| 3 | `Ant Group\Aspect\AspectService.exe` | 244 | 蚂蚁安全客户端 |
| 4 | `TeamFile\teamfile-daemon.exe` | 207 | |
| 5 | `Antding.exe`（钉钉主进程） | 157 | |

> `tblive.exe` 占用 2100，断崖式领先第二名，且它是 Active 期间的最大活动源 —— 元凶明确。

### 3. 事件日志佐证

```
21:07:48  WLAN AutoConfig 检测到受限连接、扩展模块重启（Wi-Fi 抖动，伴随现象）
（21:08 ~ 22:54 系统层面无任何"进入待机"事件，长达 1 小时 47 分空白）
22:54:57  Win32k: Power Manager 请求抑制所有输入 (INPUT_SUPPRESS_REQUEST=1)  ← 此刻才真正开始入睡
23:25:03  进入 Suspended（休眠兜底生效）
```

`Power Manager 请求抑制输入` 是系统真正开始进入待机的标志动作，它直到 22:54 才出现，印证"21:05 合盖后近 2 小时系统从未尝试入睡"。

### 4. 当前复核

- 此刻 `tblive.exe` 已不在进程列表（直播插件已退出），`powercfg /requests` 显示"执行/SYSTEM 请求：无"。
- 与"22:54 系统终于能睡"完全吻合 —— **就是 tblive 退出后系统才睡得着**。

---

## 三、三次问题对比（重要：根因各不相同）

| 时间 | 现象 | 根因 | 性质 | 兜底休眠是否生效 |
|------|------|------|------|------------------|
| 06-16 21:27 | 待机但发烫，掉 34% | 音频总线赖着不进低功耗 | 进了待机，**没睡熟** | 当时还没设置 |
| 06-17 02:22 | ✅ 正常 | — | 待机→16分钟后休眠 | ✅ 生效 |
| **06-17 21:05** | **发烫，掉 56%** | **tblive.exe 阻止进入睡眠** | **根本没进入待机** | ❌ 无法生效(前提未满足) |

> 现代待机的麻烦就在于：阻止睡眠的方式有很多种。光靠"待机后兜底休眠"挡得住"睡不熟"，但挡不住"程序强行不让睡"。

---

## 四、解决方案

### ⭐ 1. 干掉/约束钉钉直播插件（针对本次元凶，最直接）

`tblive.exe` 是钉钉的直播组件。它高强度后台运行并阻止睡眠，通常是因为**看过钉钉直播后插件没退出、或直播进程卡死**。

- **合盖前**：彻底退出钉钉（托盘图标右键 → 退出，而不是只关窗口），尤其是看过直播后。
- **临时处理**：在任务管理器里结束 `tblive.exe` 进程。
- **排查**：在 钉钉设置里关闭直播相关的后台/自动播放；若不用钉钉直播，可考虑禁用该插件。

### ⭐ 2. 给"阻止睡眠"上一道总保险：合盖强制睡眠 + 空闲超时睡眠

由于阻止睡眠的程序防不胜防，建议加两道与"程序请求"无关的强制机制：

**(a) 让程序无法用"执行请求"赖着不睡** —— 设置系统空闲超时，并忽略应用的 away/execution 请求：
```powershell
:: 电池下 10 分钟无活动强制睡眠（即使有程序请求保持唤醒）【管理员】
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 600
powercfg /setactive SCHEME_CURRENT
```

**(b) （可选，较激进）合盖直接休眠** —— 但你希望"开盖秒回桌面、不按开机键"，所以**不推荐**休眠；保持现状(合盖=睡眠)即可，重点靠方案 1 + 2(a)。

### 3. 检查并清理"阻止睡眠"的常驻程序

下次再发现没入睡，**立刻**用管理员命令抓现行：
```powershell
powercfg /requests
```
看 `SYSTEM:` 和 `执行:` 两栏里列出的进程/驱动，就是当时阻止睡眠的元凶。

也可事后用：
```powershell
powercfg /sleepstudy /output "%USERPROFILE%\Desktop\sleepstudy.html"
```
看最近的会话是 **Active** 还是 **Sleep**：
- 是 **Active** → 程序阻止了入睡（本次情况），查进程 CPU 排名。
- 是 **Sleep 但 SW/HW 低** → 待机降不下去（上次情况），查组件活跃排名。

### 4. 永久豁免（进阶，可选）

若确认某进程反复阻止睡眠又必须运行，可用 requestsoverride 限制它（谨慎使用）：
```powershell
:: 例：禁止某进程发起 SYSTEM 唤醒请求【管理员】
powercfg /requestsoverride PROCESS tblive.exe SYSTEM
:: 查看已有覆盖
powercfg /requestsoverride
```

---

## 五、行动清单

- [ ] **立即**：合盖前彻底退出钉钉（尤其看过直播后），或在任务管理器结束 `tblive.exe`。
- [ ] **加保险**：管理员执行 `powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 600` + `setactive`，让电池下 10 分钟空闲强制睡眠。
- [ ] **下次异常时**：第一时间 `powercfg /requests`（管理员）抓住正在阻止睡眠的进程。
- [ ] **长期**：观察是否只有"看过钉钉直播"后才复现；若是，向钉钉反馈 tblive 插件不退出的问题，或禁用直播插件。

---

## 附：本次新增/用到的命令

```powershell
:: 抓"谁在阻止睡眠"（最关键，需管理员）
powercfg /requests

:: 看最近会话是 Active(被阻止入睡) 还是 Sleep(睡了)
powercfg /sleepstudy /output "%USERPROFILE%\Desktop\sleepstudy.html"

:: 空闲超时强制睡眠（绕过程序的 away 请求）【管理员】
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 600
powercfg /setactive SCHEME_CURRENT

:: 限制某进程的唤醒请求（进阶，需管理员）
powercfg /requestsoverride PROCESS tblive.exe SYSTEM EXECUTION DISPLAY
powercfg /requestsoverride        :: 查看已有覆盖

:: 当前是否有 tblive 等进程
powershell -Command "Get-Process | Where-Object {$_.ProcessName -match 'tblive|Antding'} | Select ProcessName,Id"
```
