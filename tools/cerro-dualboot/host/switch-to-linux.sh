#!/bin/bash
# Host-side: switch phone from Android (slot A) to Linux (slot B).
# Android has no root (no KernelSU yet), so the switch goes through fastboot:
#   adb reboot bootloader -> fastboot set_active b -> fastboot reboot
# Reuses the running unattended-flash watcher conventions: also auto-continues
# if the device is ALREADY in fastboot/bootloader.
set -uo pipefail
LOG=${LOG:-/tmp/cerro-switch.log}
log(){ echo "$(date +%H:%M:%S) $*" | tee -a "$LOG"; }

adb_has(){ adb devices 2>/dev/null | grep -Eq $'\t(device|recovery)$'; }
fb_has(){ fastboot devices 2>/dev/null | awk 'NF>=2{exit 0} END{exit 1}'; }

log "=== cerro dualboot: Android(slot A) -> Linux(slot B) ==="
if adb_has; then
  log "adb online -> reboot bootloader"
  adb reboot bootloader
elif fb_has; then
  log "already in fastboot"
else
  log "no adb/fastboot; waiting up to 120s for either"
  for i in $(seq 1 60); do adb_has && break; fb_has && break; sleep 2; done
  adb_has || fb_has || { log "TIMEOUT: no device"; exit 1; }
fi
for i in $(seq 1 45); do fb_has && break; sleep 2; done
fb_has || { log "no fastboot"; exit 1; }

fastboot getvar current-slot 2>&1 | head -1 | tee -a "$LOG"
log "set_active b"
fastboot set_active b | tee -a "$LOG"
log "reboot"
fastboot reboot | tee -a "$LOG"

log "watch ACM (up to 90s)"
for i in $(seq 1 30); do ls /dev/ttyACM0 >/dev/null 2>&1 && { log "ACM UP +$((i*3))s"; break; }; sleep 3; done
ls /dev/ttyACM0 >/dev/null 2>&1 || { log "NO ACM (check phone)"; exit 1; }
log "OK: Linux booting on slot B; ACM console at /dev/ttyACM0"
