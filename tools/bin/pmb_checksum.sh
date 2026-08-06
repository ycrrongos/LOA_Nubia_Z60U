#!/bin/bash
# 生成内核包的 checksum(下载内核 tarball 并算 SHA512)
set -e
cd /mnt/data/LOA_Nubia_Z60U
LOG=build/pmb_checksum.log
: > "$LOG"
echo "=== $(date) ===" >> "$LOG"
PMB="python3 pmbootstrap/repo/pmbootstrap.py -c pmbootstrap/pmbootstrap_v3.cfg"
echo "=== running: $PMB checksum linux-nubia-cerro ===" >> "$LOG"
$PMB checksum linux-nubia-cerro >> "$LOG" 2>&1
echo "=== checksum exit=$? ===" >> "$LOG"
echo "=== 生成的 APKBUILD sha512sums ===" >> "$LOG"
grep -A5 "^sha512sums=" pmbootstrap/pmaports/device/testing/linux-nubia-cerro/APKBUILD >> "$LOG" 2>&1
echo "=== DONE ===" >> "$LOG"
