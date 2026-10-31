# Cerro active experiment card

## status

`done`（PASS，2026-10-31）

## one_variable

A1-投递：只把 camss/cci/camcc 系 `.ko` 用**安全路径**装进手机 `/usr`（归档仅含 `lib/modules/<kver>/...`，**禁止** `tar -C /`），装后 `depmod` + 逐个 `modprobe`/`rmmod` 验证可干净加载。不改 DT、不刷机、不碰蜂窝/音频。

## falsifier

- 装包后 `/lib` 不再是 `usr/lib` 的 symlink（= 10-23 事故重演，立即 FAIL）。→ 未发生（前后均 `usr/lib`）
- 任一模块 modprobe 后 dmesg 出现 oops/panic 或整机重启（boot id 变）。→ 未发生（boot id `287f1420…` 全程不变）
- vermagic 与运行内核不符导致 insmod 拒载。→ 首轮 camss 曾 Unknown symbol（v4l2-async/fwnode 未编出），补编两模块 + softdep 后 PASS。

## blast_radius

手机 `/usr/lib/modules/` + 动态加载驱动。未碰音频、蜂窝、显示、电源链。

## regression_must_pass

- ACM 可登录 ✓、boot id 不变 ✓（`287f1420…`）。
- HiFi Speaker `paplay` ✓（default sink `HiFi__Speaker__sink`，`Front_Center.wav` OK）。
- Wi‑Fi ✓（会话全程走 `192.168.0.68`）。
- `/lib -> usr/lib` ✓。

## evidence_log

- 2026-10-31：上一枪遗留 `/tmp/cerro-cam-modules.tar` 已被清（/tmp 清空）；主机 `build/linux-7.2`（7.2.0-rc5-dirty）三 .ko 复用 + 补编 `v4l2-async/fwnode`（缺 `bc`、`Module.symvers` 悬空链接均修复）。
- 2026-10-31 投递：tar（sha `d7d9d3e1…`）经 Wi‑Fi scp → `tar -C /usr`；`install -D` 补两 v4l2 模块；`/etc/modprobe.d/cerro-camss.conf` softdep。
- 2026-10-31 验收：全栈 modprobe rc=0、无 oops；全栈 rmmod 干净后单命令 `modprobe qcom-camss` rc=0；无 media/video 节点（DT disabled，预期）。
