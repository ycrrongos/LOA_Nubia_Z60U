# Cerro / LOA_Nubia_Z60U — Agent 强制约定

每次新对话**先读本文件**，再读 `notes/cerro-linux-bringup.md` 当前状态段，再动手。  
违反过的坑下面都标了「曾反复被骂」——当硬规则，不要再犯。

## 1. 经验文档（最高优先级，曾反复被骂）

- **每次**踩坑、探针结论、误刷路径、PASS/FAIL 判定变更，**立刻追加**到 `notes/cerro-linux-bringup.md`（硬件事实进 `notes/cerro-hardware.md`）。
- 黑屏 / fastboot / MemoryDump / 编译失败时：**先查该 md，再改代码**。
- 改 step / 出新镜像 / 改判定逻辑后，同步更新时间线与「当前状态」；不确定的结论要标证据等级，**按聊天记录核对**，禁止只靠记忆。
- 用户问「是不是又忘写 md」时：先补文档，再继续实验。

## 2. 观察优先于结论

- 进 **9008 / fastboot / Dump** 后：先看 USB ID / ACM / 本枪标记，**再下结论、再改代码**。
- 刷完**不要停**：继续盯设备状态，直到判出 PASS/FAIL/hang/dump。
- cerro **崩/hang 几乎不会自动进 9008**；进 9008 基本靠手动或舵机手。Dump（`19d2:0112`）≠ 9008。
- 线没插好 ≠ 脚本坏了；先确认 USB。

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
- **Aurora 优先（蜂窝等原厂行为）**：IPA、modem、rmnet 以及其它「安卓上是好的、主线对不上」的地方，先对照本机 Aurora 树 `/mnt/data/ArtistAOSP`（设备树 `source/device/nubia/cerro`，下游 IPA 在 `source/kernel/nubia/sm8650-modules/qcom/opensource/dataipa`）。主线表经常从旧 IPA 版本抄过来（v5.5 下行口 EP23/EP24 就是这样）。需要实机对照时可以重启进 Android 抓环境；切槽前先告诉用户。不要为了抓 log 去刷掉 Linux。

## 7. 沟通与工作方式

- 默认用**中文**简短汇报；上下文再长也不要无故切英文。
- 用户说「继续」：读 md 当前卡点 → 做下一步 → 写 md → 刷/观察。
- 需要用户操作（手动 9008、看屏、跳过解锁）时**直接说清楚要干什么**，不要闷头改完不刷也不看。
- 自动化能覆盖的（摸内存、刷机监听）用脚本；需要归因时再深入分析，避免手工空烧 token。
- 不要换 ABL/XBL；不要把 MemoryDump 当 EDL；不要在未观察 USB 时宣称「刷成功/失败」。
