#!/bin/bash
# Time only, e.g. "9:19am" (open the macOS menu bar for the date).
# After each update, wait exactly until the next minute starts, so the clock
# changes on the minute instead of drifting up to update_freq seconds behind.
now_s=$(date +%S)
sketchybar --set "$NAME" label="$(date +'%-I:%M%p' | tr 'A-Z' 'a-z')" \
                         update_freq=$((60 - 10#$now_s))
