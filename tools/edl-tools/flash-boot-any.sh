#!/usr/bin/env bash
# Flash cerro boot via EDL 9008 (preferred when available) or fastboot.
# If fastboot rejects size / fails, fall through to wait for 9008.
set -euo pipefail
BOOT=${1:-/mnt/data/LOA_Nubia_Z60U/build/boot_repack/boot-v2-builtin-dtb.img}
STOCK_VB=/mnt/data/LOA_Nubia_Z60U/tools/edl-tools/pmos-flash/backup-20260806-020517/vendor_boot_a.img
test -f "$BOOT"

flash_edl() {
  echo "==== via EDL 9008 ===="
  EDL_DIR=/mnt/data/LOA_Nubia_Z60U/tools/edl-tools
  LOADER="$EDL_DIR/nubia_sm8650_eng/prog_ufs_firehose_sm8650_v1_ddr.elf"
  PYBIN="$EDL_DIR/venv/bin/python3"
  BUS=$(lsusb -d 05c6:9008 | sed -n 's/Bus \([0-9]*\) Device \([0-9]*\).*/\1/p')
  DEVN=$(lsusb -d 05c6:9008 | sed -n 's/Bus \([0-9]*\) Device \([0-9]*\).*/\2/p')
  sudo chmod 666 "/dev/bus/usb/$BUS/$DEVN"
  EDL() { sudo -E "$PYBIN" "$EDL_DIR/edl/edl.py" --loader="$LOADER" "$@"; }
  EDL w boot_a "$BOOT"
  EDL w boot_b "$BOOT"
  EDL w vendor_boot_a "$STOCK_VB"
  EDL w vendor_boot_b "$STOCK_VB"
  EDL e dtbo_a || true
  EDL e dtbo_b || true
  EDL reset || true
}

if lsusb | grep -q '05c6:9008'; then
  flash_edl
  exit 0
fi

if lsusb | grep -q '18d1:d00d' && fastboot devices 2>/dev/null | grep -q fastboot; then
  echo "==== via fastboot ===="
  if fastboot flash boot_a "$BOOT" && fastboot flash boot_b "$BOOT"; then
    fastboot erase dtbo_a 2>/dev/null || true
    fastboot erase dtbo_b 2>/dev/null || true
    fastboot continue 2>/dev/null || fastboot reboot 2>/dev/null || true
    exit 0
  fi
  echo "WARN: fastboot flash failed — try oem edl / wait for 9008"
  fastboot oem edl 2>/dev/null || fastboot reboot-edl 2>/dev/null || true
fi

echo "waiting for 9008 (or healthy fastboot)..."
for i in $(seq 1 120); do
  if lsusb | grep -q '05c6:9008'; then
    flash_edl
    exit 0
  fi
  if lsusb | grep -q '18d1:d00d' && fastboot devices 2>/dev/null | grep -q fastboot; then
    if fastboot flash boot_a "$BOOT" && fastboot flash boot_b "$BOOT"; then
      fastboot erase dtbo_a 2>/dev/null || true
      fastboot erase dtbo_b 2>/dev/null || true
      fastboot continue 2>/dev/null || fastboot reboot 2>/dev/null || true
      exit 0
    fi
  fi
  if lsusb | grep -q '19d2:0112'; then
    echo "[$i] MemoryDump — 强制关机后音量±进 9008"
  fi
  sleep 2
done
echo "TIMEOUT: no fastboot/9008"
exit 1
