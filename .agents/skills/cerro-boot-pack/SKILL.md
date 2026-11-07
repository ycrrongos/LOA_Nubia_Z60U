---
name: cerro-boot-pack
description: >-
  Cerro (Nubia Z60U) Linux boot.img packaging. Use before building or flashing
  any dualboot boot image, when the user mentions mkbootimg/splice/方案E/验证值/
  header ID/disp-r1/cam-c1, or after a black-screen / ABL-reject boot attempt.
  Encodes clone+splice vs scheme-E full relink, guard-kernel-tree, and ID audit limits.
---

# Cerro boot packaging

Hard USB/slot rules stay in root `AGENTS.md`. This skill is **how to build the
boot.img** so packaging mistakes are not misread as panel or AVB bugs.

Also load: `cerro-bringup-gate`, `verification-before-completion`.

## Choose a path (one only)

### A. Daily / init-only（优先）

From `notes/cerro-daily-boot-fix.md`:

1. **Clone** a proven image (`linux-debug.img` or current rescue).
2. Splice only embedded initramfs `/init` and/or header cmdline.
3. Keep **127 B stub** ramdisk size; do **not** grow ramdisk in the boot header.
4. Do **not** treat full `mkbootimg` rebuild as the daily path.

### B. 方案 E（Image/DTB 变大，等长 splice 做不到）

Proven by cam-c1 (boots without panel; ACM getty may be missing):

1. Extract gzip initramfs from a **running-good** Image →
   `usr/cerro-initramfs.cpio.gz` (must keep `cerro_fix_lib` / `CONSOLE_ON` stack).
2. Install new DTB to `arch/arm64/kernel/sm8650-nubia-cerro.dtb`, delete `.dtb.o`.
3. `make ARCH=arm64 LLVM=1 Image`.
4. `mkbootimg` using **rescue header params** (v2, pagesize 4096, offsets, 127 B stub).
5. Pad to **100663296** (96 MiB).
6. Run `tools/guard-kernel-tree.sh` PASS; record tree sha in bringup.

### C. Forbidden as “fix”

- Blindly rewriting only ID bytes at offset 576..595 and calling it fixed.
- Claiming FAIL is “forgot verification ID” without unpack+rebuild audit.
- Full mkbootimg from scratch **without** reusing rescue header params / without
  the known-good embedded initramfs closure.

## ID audit (optional, not decisive)

```text
stored = boot[576:596]
expected = mkbootimg(rebuild from unpack_bootimg --format=mkbootimg)[576:596]
```

| Result | Meaning |
|--------|---------|
| mismatch | Possible stale ID (rescue historically mismatched **and still boots**) |
| match | Required metadata OK — **does not** prove panel or early boot health |

## Flash / observe notes

- On live Linux: `dd` to `/dev/disk/by-partlabel/boot_b`, read back sha, then reboot.
- `reboot bootloader` often **does not** enter fastboot on this Debian rootfs.
- In fastbootd, `erase dtbo_*` may fail → zero-fill flash same partition size.
- **中间刀观察从简**：刷完盯 `1d6b:0104`（USB 认出/能连）即可判「没早死」；不要默认等完整桌面/长 ACM。ACM getty 有更好，没有就 ICMP。
- **战役终判**显示恢复：本树镜像 + USB 活着 + 用户目视有图（仅 fb0 ≠ PASS）。
- rescue/好内核 blob 能亮 = 锚点，**禁止**当「显示栈已恢复、别再重建」。

## Current campaign pointer

See `notes/cerro-display-campaign.md`: cam-c1/scheme-E base → minimal panel
deltas until the **maintainable tree** lights the panel. Anchor brightness ≠ done.
