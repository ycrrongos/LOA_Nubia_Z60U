# Cerro active experiment card

## status

`done`（A1-DT PASS，2026-10-31）

## one_variable

（历史）A1-DT 判别-2 → 最终形态：cam-c1 DTB（camss+CCI enabled）+ `cerro-camss-load.service`（After=graphical，正常开机路径）自动加载相机栈。

## falsifier

（全部未命中）开机即冻（unit 在 graphical 后加载，安全）；CCI probe 挂（无辜）；camss 手动 probe 挂（t+10min 无辜；竞态仅限早期 udev autoload）。

## blast_radius

boot_b（cam-c1 镜像 sha `e7e79456…`）+ 手机 unit/NM profile。A 槽安卓全程 Successful=1。

## regression_must_pass

全过：`/dev/media0`+video×17、sddm active、HiFi `paplay` OK、boot 稳定 15min+、qbootctl A 槽不变。

## evidence_log

- 2026-10-31 冻死#1（真，udev 早期 autoload 竞态）→ fastboot 回滚（用户手动）。
- 2026-10-31 relink-test：重链无罪（老 DTB + 重链 Image 300s+ 稳）。
- 2026-10-31 黑名单受控 probe：CCI rc=0 无辜；camss rc=0 t+10min 无辜 → 竞态=早期时序。
- 2026-10-31 unit 方案冷启 PASS：两 modprobe SUCCESS（11:40:25）、media0+video×17、回归绿。中途两次「假冻死」误判（ACM getty 缺 + usb0 晚配），已修 usb0 NM profile；教训入 bringup。
- 遗留子项：早期竞态根因、cam-c1 无 ACM getty、sensor 驱动移植。
