#!/bin/sh
# Run after PipeWire/WirePlumber: expose the UCM speaker sink to KDE.
# Prefer the native HiFi profile; retain a manual ALSA sink only as fallback.

log() { echo "cerro-audio-session: $*" >&2; }

i=0
while [ "$i" -lt 90 ]; do
  grep -q SM8650CERRO /proc/asound/cards 2>/dev/null && break
  sleep 1
  i=$((i + 1))
done
grep -q SM8650CERRO /proc/asound/cards 2>/dev/null || {
  log "no ALSA card"
  exit 0
}

if ! command -v pactl >/dev/null 2>&1; then
  log "no pactl"
  exit 0
fi

# Wait until the Pulse-compatible server answers, not merely until its socket
# exists.  Socket activation can otherwise race WirePlumber's card discovery.
i=0
while [ "$i" -lt 45 ]; do
  pactl info >/dev/null 2>&1 && break
  sleep 1
  i=$((i + 1))
done

idx=$(pactl list short cards 2>/dev/null | awk '/platform-sound/{print $1; exit}')
sn=""

# Remove only an old Cerro fallback module before asking WirePlumber to own
# hw:0 through the UCM profile.  This also makes upgrades from the old helper
# idempotent without touching unrelated Pulse modules.
pactl list short modules 2>/dev/null | while IFS="$(printf '\t')" read -r mid mname margs; do
  [ "$mname" = module-alsa-sink ] || continue
  case "$margs" in
    *sink_name=cerro_speaker*) pactl unload-module "$mid" >/dev/null 2>&1 || true ;;
  esac
done

if [ -n "$idx" ] && pactl set-card-profile "$idx" HiFi >/dev/null 2>&1; then
  i=0
  while [ "$i" -lt 10 ]; do
    sn=$(pactl list short sinks 2>/dev/null | awk '/platform-sound.*HiFi.*Speaker/{print $2; exit}')
    [ -n "$sn" ] && break
    sleep 1
    i=$((i + 1))
  done
fi

# Fallback for a broken/missing UCM installation.  plughw is first because raw
# hw module creation may succeed but fail asynchronously on first activation.
if [ -z "$sn" ]; then
  [ -n "$idx" ] && pactl set-card-profile "$idx" off >/dev/null 2>&1 || true
  amixer -c0 cset name='PRIMARY_MI2S_RX Audio Mixer MultiMedia1' on,on >/dev/null 2>&1 || \
    amixer -c0 cset name='PRIMARY_MI2S_RX Audio Mixer MultiMedia1' 1,1 >/dev/null 2>&1 || true
  if ! pactl list short sinks 2>/dev/null | grep -q '[[:space:]]cerro_speaker[[:space:]]'; then
    pactl load-module module-alsa-sink \
      device=plughw:0,0 \
      sink_name=cerro_speaker \
      sink_properties=device.description=Cerro_Speakers \
      rate=48000 format=s16le channels=2 >/tmp/cerro-pactl-load.err 2>&1 || \
    pactl load-module module-alsa-sink \
      device=hw:0,0 \
      sink_name=cerro_speaker \
      sink_properties=device.description=Cerro_Speakers \
      rate=48000 format=s16le channels=2 >/tmp/cerro-pactl-load.err 2>&1 || true
  fi
  sn=$(pactl list short sinks 2>/dev/null | awk '/[[:space:]]cerro_speaker[[:space:]]/{print $2; exit}')
fi

if [ -n "$sn" ]; then
  pactl set-default-sink "$sn" >/dev/null 2>&1 || true
  pactl set-sink-mute "$sn" 0 >/dev/null 2>&1 || true
  pactl set-sink-volume "$sn" 80% >/dev/null 2>&1 || true
  log "default sink=$sn"
else
  log "warn: no usable sink"
fi
exit 0
