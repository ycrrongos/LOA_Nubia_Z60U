#!/bin/sh
# Initialize Cerro's volatile primary GSM/UMTS/LTE provisioning session.
# Subscriber/application identifiers are kept only in shell variables and are
# never written to stdout, stderr, or the journal.
set -eu

QMI_DEVICE=${CERRO_QMI_DEVICE:-qrtr://0}

log() {
  echo "cerro-cellular: $*" >/dev/kmsg 2>/dev/null || \
    echo "cerro-cellular: $*"
}

i=0
while [ "$i" -lt 45 ]; do
  status=
  if status=$(timeout -k 2 6 qmicli --device="$QMI_DEVICE" \
      --uim-get-card-status 2>&1); then
    if printf '%s\n' "$status" |
        grep -q "Primary GW:.*slot '1'.*application '1'"; then
      unset status
      log "primary GW session already active"
      exit 0
    fi

    aid=$(printf '%s\n' "$status" |
      sed -n '/Application ID:/{n;p;q;}' |
      tr -cd '0-9A-Fa-f')
    unset status

    if [ "${#aid}" -eq 32 ]; then
      if timeout -k 2 8 qmicli --device="$QMI_DEVICE" \
          "--uim-change-provisioning-session=session-type=primary-gw-provisioning,activate=yes,slot=1,aid=$aid" \
          >/dev/null 2>&1; then
        unset aid
        log "primary GW session activated"
        exit 0
      fi
    fi
    unset aid
  fi

  i=$((i + 1))
  sleep 2
done

log "primary GW session unavailable after bounded wait"
exit 1
