#!/bin/bash
# Ping Google's DNS every update and colour the icon:
#   green   online
#   yellow  slow (average round trip 100ms or more)
#   red     offline (2 failed pings in a row, so one lost packet doesn't count)

source "$CONFIG_DIR/colors.sh"

SLOW_MS=100
FAILS_FILE="${TMPDIR:-/tmp}/sketchybar-ping-fails"

if RESULT=$(ping -c 1 -W 1000 -t 2 8.8.8.8 2>/dev/null); then
    echo 0 > "$FAILS_FILE"
    LATENCY=$(awk -F '/' 'END { print int($5) }' <<<"$RESULT")
    if [ "$LATENCY" -lt "$SLOW_MS" ]; then COLOR=$GREEN_ICON; else COLOR=$YELLOW_ICON; fi
else
    FAILS=$(( $(cat "$FAILS_FILE" 2>/dev/null || echo 0) + 1 ))
    echo "$FAILS" > "$FAILS_FILE"
    [ "$FAILS" -ge 2 ] || exit 0   # first miss: keep showing the last state
    COLOR=$RED_ICON
fi

sketchybar --set "$NAME" icon.color="$COLOR"
