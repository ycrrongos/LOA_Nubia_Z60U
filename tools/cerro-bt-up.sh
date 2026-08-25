#!/bin/sh
# Bring up the Cerro WCN7850 controller without deprecated hciconfig.
KVER=$(uname -r)
BASE=/lib/modules/$KVER
BT_INDEX=${CERRO_BT_INDEX:-0}
BT_DEVICE=${CERRO_BT_DEVICE:-hci0}
BT_PUBLIC_ADDR=${CERRO_BT_PUBLIC_ADDR:-02:00:95:0B:4D:FF}

log() { echo "cerro-bt: $*" >/dev/kmsg 2>/dev/null || echo "cerro-bt: $*"; }
loaded() { lsmod 2>/dev/null | grep -q "^$1 "; }
load1() {
  m=$1
  loaded "$m" && return 0
  if [ -f "$BASE/${m}.ko" ]; then
    insmod "$BASE/${m}.ko" && return 0
  fi
  f=$(find "$BASE" -name "${m}.ko" 2>/dev/null | head -1)
  [ -n "$f" ] || return 1
  insmod "$f"
}

for m in rfkill kpp ecc ecdh_generic bluetooth btbcm btqca hci_uart; do
  if load1 "$m"; then
    log "loaded $m"
  else
    log "warn: load $m failed"
  fi
done

i=0
while [ "$i" -lt 40 ]; do
  [ -e "/sys/class/bluetooth/$BT_DEVICE" ] && break
  sleep 1
  i=$((i + 1))
done
rfkill unblock bluetooth 2>/dev/null || true

# WCN7850 initially reports an invalid 00:00:00:00:5A:AD address.  The kernel
# intentionally leaves such a controller HCI_UNCONFIGURED/DOWN RAW.  Configure
# the public address proven on this handset through the BlueZ management API;
# this transitions it to a normal powered controller.
if command -v btmgmt >/dev/null 2>&1; then
  if ! timeout -k 2 6 bluetoothctl list 2>/dev/null | \
      grep -qi "^Controller $BT_PUBLIC_ADDR "; then
    i=0
    while [ "$i" -lt 4 ]; do
      if timeout -k 2 8 btmgmt -i "$BT_INDEX" public-addr "$BT_PUBLIC_ADDR" \
          >/dev/null 2>&1; then
        log "configured $BT_DEVICE public address"
        break
      fi
      sleep 2
      i=$((i + 1))
    done
  fi
  timeout -k 2 8 btmgmt -i "$BT_INDEX" power on >/dev/null 2>&1 || true
elif command -v hciconfig >/dev/null 2>&1; then
  hciconfig "$BT_DEVICE" up 2>/dev/null || true
fi

if command -v btmgmt >/dev/null 2>&1; then
  if timeout -k 2 6 bluetoothctl list 2>/dev/null | \
      grep -qi "^Controller $BT_PUBLIC_ADDR "; then
    log "done; configured controller present"
  else
    log "done; no configured controller"
  fi
else
  log "done; $(hciconfig "$BT_DEVICE" 2>/dev/null | head -3 | tr '\n' ' ')"
fi
exit 0
