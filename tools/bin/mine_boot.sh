#!/usr/bin/env bash
# Extract boot_a header (offsets/pagesize) and default primary display panel.
set -u
ROOT=/mnt/data/LOA_Nubia_Z60U
OUT=$ROOT/downstream-dt
BK=/mnt/data/ArtistAOSP/backups/device-dump-20260717-222750/by-name
N=$ROOT/notes
F=$OUT/dts/dtbo_1.dts

{
  echo "===== boot_a header ====="
  mkdir -p "$OUT/boot_unpack"
  unpack_bootimg --boot_img "$BK/boot_a.img" --out "$OUT/boot_unpack" 2>&1 | sed -n '1,40p'
  echo
  echo "===== boot_unpack files ====="
  ls -l "$OUT/boot_unpack"
} > "$N/mine_boot.txt" 2>&1

{
  echo "===== primary dsi display default panel ====="
  grep -n -E "qcom,dsi-display-primary|qcom,dsi-display-active|qcom,dsi-panel" "$F" | head -20
  echo "===== vtdr6130 / rm692h0 panel node headers ====="
  grep -n -E "vtdr6130|rm692h0|bf068" "$F" | head -20
  echo "===== usb / dwc3 / maximum-speed ====="
  grep -n -iE "dwc3|maximum-speed|usb2-phy|usb-role-switch|extcon" "$F" | head -15
} > "$N/mine_boot_disp.txt" 2>&1

echo "DONE"; wc -l "$N/mine_boot.txt" "$N/mine_boot_disp.txt"
