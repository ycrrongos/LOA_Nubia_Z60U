#!/bin/sh
# Mark the boot successful only after Qualcomm A/B partitions are discoverable.
set -eu
export LC_ALL=C

log() { echo "cerro-qboot-mark-success: $*" >&2; }

i=0
while [ "$i" -lt 60 ]; do
  active=$(/usr/bin/qbootctl -a 2>&1 | sed -n 's/^Active slot: //p' | tail -n 1)
  current=$(/usr/bin/qbootctl -c 2>&1 | sed -n 's/^Current slot: //p' | tail -n 1)
  case "$active:$current" in
    _a:_a|_b:_b)
      log "active=$active current=$current; marking successful"
      exec /usr/bin/qbootctl -m
      ;;
  esac
  log "slots not ready or disagree (active=${active:-unknown}, current=${current:-unknown}); retry $((i + 1))/60"
  sleep 2
  i=$((i + 1))
done

log "timed out waiting for consistent A/B slot metadata"
exit 1
