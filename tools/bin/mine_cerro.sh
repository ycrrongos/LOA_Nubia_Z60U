#!/usr/bin/env bash
# Mine the cerro-specific dtbo overlay for key hardware config.
set -u
ROOT=/mnt/data/LOA_Nubia_Z60U
OUT=$ROOT/downstream-dt
F=$OUT/dts/dtbo_1.dts
N=$ROOT/notes

{
  echo "===== nubia/cerro/nx721 context ====="
  grep -n -iE "nubia|cerro|caza|nx721" "$F" | head -60
} > "$N/mine_ids.txt" 2>&1

{
  echo "===== panel-name ====="
  grep -n -E "qcom,mdss-dsi-panel-name" "$F" | head -30
  echo "===== panel compatibles ====="
  grep -n -E 'compatible = "[^"]*panel[^"]*"' "$F" | sort -u | head -40
  echo "===== panel physical / resolution ====="
  grep -n -E "qcom,mdss-(pan-physical|dsi-panel-width|dsi-panel-height|dsi-panel-framerate)" "$F" | head -20
} > "$N/mine_panel.txt" 2>&1

{
  echo "===== touchscreen chips ====="
  grep -n -iE "goodix|focaltech|synaptics|novatek|ilitek|nt36|ft[0-9]{4}|gt[0-9]{3,4}" "$F" | head -40
  echo "===== touch nodes compatible ====="
  grep -n -E 'compatible = "[^"]*(touch|ts)[^"]*"' "$F" | sort -u | head -20
} > "$N/mine_touch.txt" 2>&1

{
  echo "===== regulator-min/max summary (unique names) ====="
  grep -n -E "regulator-name" "$F" | head -80
} > "$N/mine_regulators.txt" 2>&1

echo "DONE"
wc -l "$N"/mine_*.txt
