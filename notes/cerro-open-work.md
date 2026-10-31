# Cerro 未完成项（按顺序做，做完才划掉）

> 2026-10-31 对照 **Aurora AOSP** 重排（用户确认：移动网络 / SIM **硬件损坏，蜂窝相关一律搁置**）。  
> 证据写进 `notes/cerro-linux-bringup.md`；改手机前填 `notes/cerro-active-experiment.md`（单变量）。  
> 崩溃观察：`tools/cerro-state-watch.py`（见 `AGENTS.md`）。

## 当前队列（非蜂窝 · 相对 Aurora 缺口）

**用户最新优先级（2026-10-31）**：先恢复丢失显示栈；相机等功能暂停。源码恢复与 disp-r1 实测见 bringup 当前记录和 active experiment。

> **原则**：做一项改一项状态；同轮禁止叠相机+传感器+音频+刷机。

### A. 明确缺口（日用影响大）

| 序 | 项 | Aurora | Linux | 难度 | 状态 |
|----|----|--------|-------|------|------|
| **A1** | **相机** | 多摄可用 | **SoC 侧 PASS（2026-10-31）**：camss+CCI enabled（`cam-c1` DTB），开机经 `cerro-camss-load.service`（After=graphical）自动加载，`/dev/media0`+video×17；早期 udev autoload 有竞态冻死（unit 时序绕开，根因未挖）。**传感器 imx800/imx906/ov12d2q/ov50e40/ov64b40 主线无驱动 = 出图的长活** | 高 | 下一刀：CCI 上摸 sensor I²C 地址（无驱动阶段先探存在性）；竞态根因与 cam-c1 boot 无 ACM getty 作旁支 |
| **A2** | **自动旋转 / 运动传感器** | `sscrpcd` + LSM6DSO（SEE/FastRPC on ADSP） | fastrpc/`hexagonrpcd -s`/registry/`sensor_pd` PASS；**IIO 空** | 中高 | 未完成；禁再拧 QRTR sensh |
| **A3** | **屏下指纹** | Goodix 可用 | `goodix,fingerprint` SPI + gpio93；**主线无驱动** | 高 | 未开做 |
| **A4** | **NFC** | ST21 + SE | `st21nfc` I²C + `st54spi`；社区有方向，**本机未做** | 中 | 未开做 |
| **A5** | **震动马达** | haptic 正常 | `haptic_hv@5A`（awinic）；**未验收** | 中低 | 未开做 |
| **A6** | **有线耳机路径** | WCD 耳机路由 | 扬声器/手麦/听筒 **PASS**；耳机 jack/Type-C 音频 **未按 Aurora 验** | 中 | 未开做 |

### B. 半成品 / 体验差一截

| 序 | 项 | 说明 | 状态 |
|----|----|------|------|
| **B1** | 墙充 PPS 大电流对照 | 电量/`charge_full*` 已 PASS；须**同一墙充口** Android↔Linux 抓 ICL/Ibat；禁 PC口 Linux vs 墙充 Android | 可选旁注 |
| **B2** | 关机充电 UI | 低电关机插电会直接再进 Linux；无 Android off-mode 充电界面 | 未开做 |
| **B3** | ToF / 闪光灯 | 跟相机捆；相机未通 ≈ 没有 | 随 A1 |
| **B4** | 游戏肩键 | DT `gpio_keys_nubia`（`game_sw_on/off`）；是否进 input、桌面可绑 **未验收** | 未开做 |
| **B5** | USB-C DP alt-mode | 硬件有 `nubia,usb_switch_dp`；Linux **未当功能验收** | 未开做 |

### C. 已基本对齐（勿当缺口重开，除非回归）

显示/触控、GPU/KDE 桌面、Wi‑Fi/BT、媒体扬声器+手麦+听筒切换、电量/充电读数、电源键熄屏亮屏（v2）、UFS/双系统、USB gadget(ACM/ECM)、开机服务持久化、桌面低电不再误关机。

### D. 蜂窝相关 · 硬件阻塞搁置（2026-10-23+）

用户确认 Aurora 上蜂窝仍挂 → **排线/座子硬件**，非 Linux 软件回归。在修好硬件前 **不要** 再开下列项：

- 移动数据 / SIM / ModemManager 再拧
- VoLTE / IMS / 通话远端声 / 短信
- GNSS/GPS（走 modem PD）
- IPA / memshare / rmtfs 为「上网」再改（稳定性补丁已进镜像的保留，勿回退）

历史已完成项仍保留在下文 §6–§8，作回归锚点；**#4 通话远端声** 一并搁置。

---

## 建议动手顺序

1. **A1 相机** — 装 ko 已 PASS（2026-10-31，产物 `build/cerro-cam-modules-20261031.tar.gz`）；下一刀 **DT enable camss/CCI**（先查供电，出新实验卡）。
2. **A2 自动旋转** — ADSP FastRPC SEE 客户端（对齐 `sscrpcd`+`sensors.qti`），再 iio-sensor-proxy；回访 `patches/sensors-hexagonrpcd-c1`、`notes/android-sensor-refs/`。
3. **A5 震动** → **A4 NFC** → **A6 耳机**（按你更在意的交互调序）。
4. **A3 指纹**（高难度，可后置）。
5. **B*** 穿插，不阻塞 A1/A2。

---

## 明细（原编号保留；状态已同步）

## 1. 媒体音频

- **状态**：完成（2026-10-20 冷启 `2a99fe89`）。audio→sddm→PW；`Active Profile: HiFi (Mic, Speaker)`；默认 `HiFi__Speaker__sink` / Loudspeaker；session 日志无 fallback；无 bootfix。
- **根因摘要**：勿 After cellular；MPSS 后再 ADSP；WP/session 须用完整 profile 名；linger PW 须等声卡。

## 2. 电量 / 充电再验收

- **状态**：builtin `/pmic-glink` **PASS**；`charge_full*` **PASS**（2026-10-21 19:52，`6080000`/`6000000`）；Android Type-C PD≈3A 与 Linux USB2 SDP500mA 基线均已抓。
- **旁注**：主机 Type-C 热插拔曾不出 ACM（误判橙屏）；冷启后 USB 数据口正常。SSH：`192.168.68.2`（ECM）/`192.168.0.247`（WiFi）。
- **剩余**→ **B1**：同一墙充口 Linux PD 电流对照。

## 3. 开机服务持久化

- **状态**：完成（2026-10-21）。`boot-v2-pmic-imem-c5-init.img`（SHA `560e3441…`）= 已知好内核 + 仅替换嵌入 init。冷启 `[cerro-s5ca]`、wants 干净、NM-wait masked、sddm active。
- **禁止**：BT/usbnet 再进 `multi-user.target.wants`；勿再把带 `CERRO_PROBE_STAGE=31` 的 `setup.c.cerro-wip` 当正式 setup 编进 Image。

## 4. 通话远端声音

- **状态**：**搁置**（2026-10-31；蜂窝硬件损坏；此前软件也未听感 PASS）。
- **历史**：2026-10-22 回退 10-17 晚 VoiceCall/callaudiod；IMS 曾关以免抢数据；AGM 共存有机器证据、听感未确认。
- **若硬件修好再开**：验收必须用 **KDE Dialer**；挂断后媒体须仍活。
- **禁止**：停 PipeWire；通话里断 MultiMedia1/suspend 不恢复；sidetone 冒充远端；`echo stop > adsp`；用 mmcli 当听感主测。

## 5. 自动旋转 → 队列 **A2**

- **状态**：未完成（2026-10-21 19:58；2026-10-31 仍开）。`hexagonrpcd -s`/fastrpc/registry/`sensor_pd` jsn PASS；IIO 空。
- **已排除**：QRTR `sensh`/`libssc`；SLPI `chrecd`（本机无 SLPI）。
- **下一步**：ADSP FastRPC SEE 客户端（对齐 Android `sscrpcd`+`sensors.qti`/`libssc_default_listener`），再接 iio-sensor-proxy。
- **回访**：`patches/sensors-hexagonrpcd-c1`；`notes/android-sensor-refs/`。

## 5b. 相机 → 队列 **A1**（当前优先）

- **状态**：装 ko **PASS**（2026-10-31；安全路径 `/usr`，`/lib` 完好；camss/cci/camcc+v4l2 栈单命令可载可卸，dmesg 零 oops）。装 ko 首次 **FAIL**（`/lib` 事故，已 debug-rescue 修）已翻页。
- **事实**：SoC CAMSS 在 livetree **disabled**；运行 DTB 无 CCI 控制器节点（仅 pinctrl）；传感器 imx800/imx906/ov12d2q/ov50e40/ov64b40（主线无驱动）。
- **模块产物**：`build/cerro-cam-modules-20261031.tar.gz`（9 ko，sha256 `d7d9d3e1…`）；手机侧 `/etc/modprobe.d/cerro-camss.conf` 有 softdep（camss 的 depends 缺 v4l2-async/fwnode，见 bringup 2026-10-31 条）。
- **门禁**：装模块路径安全（`tar -C /usr` 或归档内仅 `lib/modules/...`）；**禁止**对 `/` 解开带顶层 `lib/` 的包。
- **禁止**：同轮动蜂窝/IMS；盲 enable camss 而不查供电；一次叠 DT+sensor+刷机。

## 5c. 指纹 → 队列 **A3**（2026-10-31 入队）

- Goodix 屏下 SPI；pwr-gpio TLMM **93**；主线无驱动；需用户态/逆向方案。见 `notes/cerro-hardware.md`。

## 5d. NFC → 队列 **A4**（2026-10-31 入队）

- `st21nfc@08` + `st54spi@0`；社区 st-nfc；本机未 enable/验收。

## 5e. 震动 → 队列 **A5**（2026-10-31 入队）

- `haptic_hv@5A`（awinic）；未装驱动/未用户态验收。

## 5f. 有线耳机 → 队列 **A6**（2026-10-31 入队）

- WCD939x 在 Aurora 有耳机路径；Linux 未按 jack/Headset UCM 对照验收（勿与通话 VoiceCall 混淆）。

## 5g. 肩键 / DP / 关机充电 UI → **B2 B4 B5**（2026-10-31 入队）

- 肩键：`gpio_keys_nubia`；DP：`nubia,usb_switch_dp`；关机充电：无 off-mode UI。

## 电量 / 充电速度（旁注）→ **B1**

- **读数**：`charge_full*` 已 PASS（勿再写「缺 charge_full」旧结论）。
- **速度**：PC USB SDP≈500mA 双侧都慢；墙充 PPS 对照仍待做。

## 6. 蜂窝下行再确认

- **状态**：软件曾完成（2026-10-19）。**硬件现坏 → 搁置复验**。
- **禁止**：`rmmod ipa`、对 AP_MODEM_RX `AGGR_FORCE_CLOSE`。

## 7. IPA IMEM 进正式镜像

- **状态**：完成（livetree `reg=<0x3000 0x2000>`）。**保留，勿回退**。
- **禁止**：刷回 `0x8000` 的 `linux-debug.img`；勿用 `CERRO_PROBE_STAGE=31` 的 WIP setup 重编。

## 8. ModemManager / qcom-modem-setup

- **状态**：软件曾完成（2026-10-21）。**硬件现坏 → 搁置**；脚本保留勿删。
- **仓库**：`tools/cerro-qcom-modem-setup.sh`、`tools/cerro-nm-wwan-on.sh`。

## 9. 桌面登录确认

- **状态**：完成（2026-10-20）。UPower `PercentageAction=0.0` + PowerDevil `BatteryCriticalAction=0`。
- **禁止**：`cerro-dpms`、greeter `DisplayServer=wayland`、改 KWin `brightness`。电源键只用 v2。
