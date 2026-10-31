# Cerro / LOA_Nubia_Z60U — Agent 强制约定

每次新对话**先读本文件**，再读 `notes/cerro-linux-bringup.md` 当前状态段，再动手。  
违反过的坑下面都标了「曾反复被骂」——当硬规则，不要再犯。

## 0. 怎么加载（防跑偏，2026-10-22）

- **根 `AGENTS.md` / `alwaysApply` rule**：主要在**用户发消息、组请求**时注入。长工具循环里模型跟轨迹走，**不会每步重读**；compaction 后更易忘。
- **定时重读守护（2026-10-31 用户要求，硬规则）**：长会话中**每 ~15 次工具调用、每个新实验刀/刷机动作开始前、任何 compaction/上下文摘要之后、以及用户在消息里提到 agentsmd 时，必须重读本文件 + `notes/cerro-active-experiment.md`**，核对当前动作是否仍符合：单变量、blast radius、回归 must-pass、槽位/刷机纪律、禁改清单。发现漂移（正在做的事和实验卡不符）**立即停手改卡**，不许将错就错。用户会不定期在消息里提醒「看 agentsmd」——那是第二道保险，不能替代自查。
- **预防**：改手机前读/写 `notes/cerro-active-experiment.md`；方法 skill `.agents/skills/cerro-bringup-gate/`；hooks（`.cursor/hooks.json`）在 `sessionStart` / 高危 `postToolUse` / `beforeShellExecution` 再灌短门禁；`preCompact` 只提示用户去 nudge。
- **禁止**再堆嵌套 `notes/**/AGENTS.md`：Cursor 常把嵌套 AGENTS 当 Always 整仓灌进上下文（论坛 3.6+）。子系统门禁用 `.cursor/rules/cerro-cellular.mdc` / `cerro-audio.mdc` 的 **`globs`**。
- 上游手机 bringup skill（网络好时装）：`git clone https://github.com/angelwzr/linux-phone-porting ~/.agents/skills/linux-phone-porting`（FlClash）。

## 1. 经验文档（最高优先级，曾反复被骂）

- **每次**踩坑、探针结论、误刷路径、PASS/FAIL 判定变更，**立刻追加**到 `notes/cerro-linux-bringup.md`（硬件事实进 `notes/cerro-hardware.md`）。
- 黑屏 / fastboot / MemoryDump / 编译失败时：**先查该 md，再改代码**。
- 改 step / 出新镜像 / 改判定逻辑后，同步更新时间线与「当前状态」；不确定的结论要标证据等级，**按聊天记录核对**，禁止只靠记忆。
- 用户问「是不是又忘写 md」时：先补文档，再继续实验。
- **未完成功能按顺序做**：`notes/cerro-open-work.md`。做完一项再做下一项，证据写回 bringup。

## 2. 观察优先于结论

- 进 **9008 / fastboot / Dump** 后：先看 USB ID / ACM / 本枪标记，**再下结论、再改代码**。
- 刷完**不要停**：继续盯设备状态，直到判出 PASS/FAIL/hang/dump。
- cerro **崩/hang 几乎不会自动进 9008**；进 9008 基本靠手动或舵机手。Dump（`19d2:0112`）≠ 9008。
- 线没插好 ≠ 脚本坏了；先确认 USB。
- **Linux 运行中 ACM / gadget 突然没了：默认按异常重启/有序关机处理（约 90%），不要先猜拔线或「脚本把 ACM 弄断」。** 立刻：`lsusb` → 等 `1d6b:0104` 回来 → 比 boot id / uptime；并用下面的 `cerro-state-watch.py`，或对 `-b -1` 看尾部是 `power off` / panic / IPA 还是真的只断串口。只有 boot id 不变且几秒内 ACM 自愈，才倾向链路抖 / getty 未起。

### 崩溃观察：`tools/cerro-state-watch.py`

适用：手机已经在跑 Linux（`1d6b:0104` / ACM），怀疑自行重启、黑屏、USB 抖动，需要把「线断了」和「系统崩了」分开。  
不适用：还在 9008/fastboot 刷机——那种继续用 `auto-flash-watch.sh` / `auto-observe-boot.sh`。本脚本会占着手机 ACM，**不要同时再跑** `cerro-acm-run.py`。

```bash
python3 tools/cerro-state-watch.py
# 或后台：
setsid python3 tools/cerro-state-watch.py >/tmp/cerro-state-watch.stdout 2>&1 < /dev/null &
```

- 日志：`/tmp/cerro-state-watch.log`（USB 状态变化 + 新 journal + 重启后上一轮 `-p err`）。
- 当前快照：`/tmp/cerro-state-watch.status`。
- 它每 0.4s 记 USB 模式：`linux` / `linux+acm` / `android` / `fastboot` / `edl` / `dump` / `none`。
- ACM 在的时候大约每 2s 读 boot id、uptime，并把新的 err 日志记下来。boot id 变了会写 `REBOOT`（这是崩溃或重启，不是拔线），并立刻拉上一轮错误。
- `linux+acm -> none` 且回来后 boot id 变了 = 崩了；boot id 没变、只是 ACM 短暂消失 = 链路抖或 getty 还没起来。

## 3. USB / 判定口诀

| ID / 现象 | 含义 |
|-----------|------|
| `05c6:9008` | EDL，可刷 |
| `18d1:d00d` / `fastboot devices` | fastboot，可刷 |
| `19d2:0112` | ZTE MemoryDump，硬崩 |
| `1d6b:0104` | USB gadget / ACM（常需 `modprobe cdc_acm`） |
| 解锁提示后立刻黑屏 | ABL 已交权（无显示时无 Nubia logo） |

- **同时检测** 9008 与 fastboot（对齐 `tools/lib/cerro-usb-detect.sh` / UotanToolboxNT 思路）。
- 探针：**晚 sticky fastboot = PASS**；**早 sticky = FAIL**；一直静默 = hang；Dump = dump。
- 解锁橙屏等待要算进计时；无人跳过时勿把 `PASS_MIN` 设短。用户明确帮跳过时用 `SKIP_UNLOCK=1`。
- **A/B 误判**：半刷会导致切槽「过一会又能进」——必须**双槽**刷 `boot_{a,b}`（及需要的 `vendor_boot_{a,b}`），擦 `dtbo_{a,b}`。判定以 ACM 里**本枪独有**标记为准，不能只看「最后能进系统」。

## 4. 无人值守刷机 / 后台（曾反复被骂）

- 用 **Cursor 后台终端**跑监听，**不要**用烧 token 的子 agent 空转盯梢。
- 推荐：`tools/edl-tools/auto-flash-watch.sh --daemon <boot.img>`；验收用 `auto-observe-boot.sh --daemon <label>`。
- 状态：`cat /tmp/cerro-auto-flash.status`，日志：`tail -f /tmp/cerro-auto-flash.log`。
- **后台终端要一直开着**，不要随手关掉；需要「跑完唤醒」时用可结束的后台命令 + 完成通知，而不是假死循环。
- 需要进 9008 时：优先舵机手 `tools/edl-tools/enter-9008-hand.sh`（**按住到出现 `05c6:9008` 再松**；脚本会顺带 ACM reboot）。没有手或失败再明确告诉用户手动进。
- 舵机串口用 Espressif **by-id**，勿占裸 `/dev/ttyACM0`（会和手机 ACM 撞车）。校准角度见 `tools/agent-phone/press-angles.env`。

## 5. 网络与 Git

- 拉 GitHub / 国外资源：**走 FlClash 代理**（本机 FlClash；给 shell/`git`/`curl` 设代理后再拉）。
- 远程：`https://github.com/ycrrongos/LOA_Nubia_Z60U`（`origin`）。未明确要求不要乱 push；要求 push 时记得代理。
- **仓库已是 git**；日常只提交 notes / tools / patches / DTS / recovery 配方，**不要**把 `build/`、`backups/`、大镜像、固件 blob、`recovery/**/out/*.img`、apk 编译中间物塞进 commit（见 `.gitignore`）。
- **提交纪律（bringup 型项目：做一步、交一步，方便回滚）**：
  1. **每完成一个可叙述的小步就本地 commit**（例：IPA WAN EP PASS、手麦 TX tplg PASS、UCM 改听筒）。不要攒一大包脏树；回滚靠 `git revert` / `git checkout <commit> -- path`。
  2. **一次 commit 只绑一个意图**（不要同时塞蜂窝 + 音频 + greeter）。相关 bringup 笔记与代码/补丁同一步一起交。
  3. **push 仍要显式**：没说 push 就不要 push；要 push 时走 FlClash 代理。本地多 commit、远端少推，很正常。
  4. 改桌面/电源/显示/SDDM 前：先在 `notes/cerro-linux-bringup.md` 记「打算改什么」；改完立刻记 PASS/FAIL 证据，再 commit。
  5. **禁止把「试坏的现场」当默认**：已知好的 rootfs 锚点是 `backups/debian-native-20260817/debian-root.tar.zst`；已知好的 dualboot boot 锚点是 `build/dualboot/linux-debug.img`。弄崩优先整盘还原锚点，不要在坏树上叠补丁。
  6. 提交前 `git status` + `git diff` 自查：有没有误加 `.img` / journal / `/tmp` / apk `obj/` 产物；说明写 **为什么**，不要只列文件名。
  7. 试错中途也可 commit，标题标明 `WIP` / `FAIL`；修好后再交 `PASS` 步，别靠「先不交、回头再想」。

## 5.2 禁止用延后/摘掉开机来假装功能完成（2026-10-19，曾明确禁止；2026-10-20 加严）

### 一律算凑合（禁止标 PASS / 禁止当「修完了」）

1. **mask** 掉会拖死开机的服务；或改成 `OnBootSec=` / `timer` 晚启；或从 `multi-user.target` / `graphical.target` 摘掉 wants，等登录后再手动 `systemctl start`。
2. 用「服务 `active`、设备节点在、SDDM 也在、冷启 N 秒后自己起来了」交差——**没有**证明根因已消。
3. **事后补救当主方案**：`bootfix` / `sleep` 轮询完再 `systemctl restart pipewire`、登录后脚本再踢一次会话、把功能挂到「等别的无关大服务」（例：音频 `After=cerro-cellular-prepare` 只为拖时间让 MPSS 碰巧起来）——这是绕开竞态，不是修好依赖。
4. 把真实硬件依赖伪装成「开机目标里晚一点自然好了」：验收必须看到 **正确的 Before/After 或脚本内对症等待**（等的是真正缺的那扇门，例如 ADSP 前先有 MPSS `running`），以及 **用户态不再早于硬件**（SDDM/PipeWire 不得在声卡出现前抢先 probe 然后靠 restart 挽回）。

### 要做的

- 服务仍走原来的开机目标（音频：`WantedBy=multi-user` + `Before=sound.target`，**不要** timer）。
- 卡住就修：**错误的 After/Wants**、脚本死等、二次 `ExecStartPost`、用户会话早于 `sound.target`/card。根因写进 bringup，带 journal 时间线（谁先谁后）。
- **完成标准**：正常冷启路径上，功能在依赖满足后一次就绪；不需要 mask/timer/摘 wants/bootfix-restart；用户能直接用（有声卡且会话里是真实 HiFi sink，不是 Dummy）。没有用户能用的功能，就不能标完成。

`cerro-audio` 挂 40s timer、只验「45s 自启 active」、或靠 `cerro-audio-bootfix` restart PW——均作废。蓝牙、usbnet、充电同样禁止用摘 wants / 晚 timer / 事后 restart 交差。

## 5.3 内核树保护（2026-10-31 显示栈丢失事故后立，曾丢整个显示栈，硬规则）

背景：10-21 清理时把从未提交的本地显示文件（panel 驱动/dsi_host 补丁/最终 setup.c）洗掉，10-31 重链镜像才暴露，代价一整天。**结构上防再犯**：

1. **内核树 `build/linux-7.2` 有自己的 git**：树内任何本地改动（`.c`/`.h`/`Kconfig`/`Makefile`/`.config`/wrap/dts）**必须随手 commit 到树内 git**；保持 `git -C build/linux-7.2 status` 干净。
2. **任何 Image / boot.img 构建打包前必须跑 `tools/guard-kernel-tree.sh` 且 PASS**：树脏=拒绝；好内核（`patches/kernel-config-good-20260817.config`）里 =y 的符号在树 config 里**蒸发**（连 `# not set` 都没有）=拒绝（=源码被删，正是面板驱动的丢失签名）；=y→=m 只警告。产出镜像必须把 guard 打印的 tree sha 记进 bringup。
3. **禁止**在内核树里 `git checkout .` / `git clean` / 批量恢复覆盖——除非先 commit 当前现场。恢复单个文件前先确认改动已提交。
4. **好内核二进制锚点**：`backups/kernel-good-20260817.bin`（sha `a6201111…`，显示/一切正常的已知好内核 blob，含丢失显示栈的编译产物，考古用）；配套 config 在 patches/。
5. 主仓库继续不收内核树与二进制（`.gitignore`）；树的安全靠树内 git + 本 guard。

## 5.1 桌面 UX / 电源键（2026-10-15/16 血泪，曾反复被骂）

根因不是「电源键本身」，是 **v2 之后又叠了一堆试验**（`cerro-dpms`、`DisplayServer=wayland` greeter、KWin `brightness=0`）把面板/会话干崩。

硬规则：

1. 电源键只用 **v2**：`tools/cerro-dualboot/linux/cerro-powerkey.py` → PowerDevil `Turn Off Screen` / `wakeup`；`kscreenlockerrc` **Autolock=false**（熄屏不锁屏，触摸/双击可亮）。
2. **禁止**安装或调用 `/usr/local/sbin/cerro-dpms`（曾 SIGSEGV）。
3. **禁止**为 greeter 写 `DisplayServer=wayland`（缺 weston；autologin 可另说）。
4. **禁止**改 `kwinoutputconfig.json` 的 `brightness` / 对面板 sysfs 刷亮度做熄屏。
5. 安装脚本：`tools/cerro-dualboot/linux/install-desktop-ux.sh`（已含上述禁令）。改 UX 只改这一条链路，验收：ACM 连续 ≥2min + 用户确认熄屏/亮屏。

## 6. 工程边界

- Path A：原厂 ABL + 自编 `boot.img`（header **v2** + 内置 DTB）；vendor_boot 保持原厂；擦 dtbo。
- 完整内核在 `build/linux/`（gitignore）；仓库以 notes / tools / patches / linux DTS 为主。
- 主屏是 **BF068 / RM692H0（1116×2480 CMD+DSC）**，不要把 Visionox VTDR6130 当主屏。
- 显示硬坑（须保留绕过）：见 bringup「当前状态」——`assigned-clocks`、bind-direct、勿乱 `component_bind_all` 等。
- 改 `/init` / 嵌入 cpio 必须重编镜像（BL initrd 故意未 apply）。
- **内置 DTB**：`prefer_builtin_dtb` 吃的是 `arch/arm64/kernel/sm8650-nubia-cerro.dtb(.o)`，不是 `boot/dts/` 那份。改 DTS 后必须 `dtc` → `cp` 到 `kernel/` → 删 `.dtb.o` 再 `make Image`，否则 cmdline 标签假更新（s5ez 教训）。
- 用户说「先刷回 AOSP / 暂不刷 Linux」时：可继续改代码，**不要擅自刷 Linux**。
- **对照顺序（曾被纠正：不能「全看安卓」）**：
  1. **优先**：网上/社区 Linux 资料（pmOS、Qualcomm Linux/AudioReach 文档、主线/pipewire/wireplumber/callaudiod issue、同类机 bringup）。
  2. **其次**：本仓库 bringup / 已验证补丁。
  3. **再次**：Aurora/Android 作「原厂行为参考」（IPA、modem、rmnet、mixer 名等）——**只取接口与事实，不要把 Android HAL/会话模型原样搬到 Linux**；主线表常从旧 IPA 抄错（v5.5 EP23/EP24），Linux 用户态是 PipeWire/UCM/AGM，不是 AudioFlinger。
  4. 需要实机 Android 对照时：切槽前先告诉用户；不要为了抓 log 刷掉 Linux。树：`/mnt/data/ArtistAOSP`（`source/device/nubia/cerro`，下游 IPA `…/dataipa`）。

### 6.1 通话验收（2026-10-22，强制）

- **测接打必须用：已登录 KDE 后的 Dialer 应用**（Plasma Dialer）。用户也用 Dialer 看状况。
- **禁止**用 `mmcli --voice-create-call` / QMI dial 当「用户可验收」的主测（信令探针可以，但**不能**据此标听感/卡死 PASS，用户看不见 Dialer UI）。
- 验收要看：Dialer 通话界面 + 听筒/扬声器有无远端声 + **挂断后媒体声是否还活着**（不得需重启才能恢复媒体）。

## 7. 沟通与工作方式

- 默认用**中文**简短汇报；上下文再长也不要无故切英文。
- 用户说「继续」：读 md 当前卡点 → 做下一步 → 写 md → 刷/观察。
- 需要用户操作（手动 9008、看屏、跳过解锁、**用 Dialer 打一通电话**）时**直接说清楚要干什么**，不要闷头改完不刷也不看。
- 自动化能覆盖的（摸内存、刷机监听）用脚本；需要归因时再深入分析，避免手工空烧 token。
- 不要换 ABL/XBL；不要把 MemoryDump 当 EDL；不要在未观察 USB 时宣称「刷成功/失败」。
