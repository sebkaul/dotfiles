#!/bin/bash
# Adjust the volume of the active media sink-input. The python module writes
# the current index to /tmp/waybar-media-sink each tick.
DIRECTION="${1:-up}"
STEP=5
CACHE=/tmp/waybar-media-sink

IDX=$(cat "$CACHE" 2>/dev/null)
[ -z "$IDX" ] && exit 0

# Sink-input indices change on app restart; bail if it's gone (daemon refreshes).
pactl list sink-inputs short 2>/dev/null | awk '{print $1}' | grep -qx "$IDX" || exit 0

case "$DIRECTION" in
    up)   pactl set-sink-input-volume "$IDX" "+${STEP}%" ;;
    down) pactl set-sink-input-volume "$IDX" "-${STEP}%" ;;
esac
