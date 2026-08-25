#!/usr/bin/env bash
# Flash a Neoteric caza fastboot img zip/dir via fastbootd (device already in fastbootd).
# Usage: flash-caza-fastbootd.sh /path/to/unzipped-imgs-or.zip
set -euo pipefail
FB="${FB:-/mnt/data/ZFlipToolBox/.android-sdk/platform-tools/fastboot}"
S="${SERIAL:-320243913409}"
SRC="${1:?img dir or zip}"
WORKDIR=$(mktemp -d /tmp/caza-flash-XXXX)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT
if [[ -f "$SRC" ]]; then
  unzip -qo "$SRC" -d "$WORKDIR"
  D="$WORKDIR"
else
  D="$SRC"
fi
cd "$D"
"$FB" -s "$S" getvar is-userspace 2>&1 | grep -q 'yes' || { echo 'need fastbootd'; exit 1; }
for p in boot init_boot dtbo recovery pvmfw vendor_boot vbmeta vbmeta_system; do
  [[ -f ${p}.img ]] && "$FB" -s "$S" flash "$p" "${p}.img"
done
"$FB" -s "$S" snapshot-update cancel || true
for p in odm product system system_dlkm system_ext vendor vendor_dlkm; do
  [[ -f ${p}.img ]] && "$FB" -s "$S" flash "$p" "${p}.img"
done
"$FB" -s "$S" format:f2fs userdata || true
"$FB" -s "$S" format:f2fs metadata || true
echo "Done. Reboot with: $FB -s $S reboot"
