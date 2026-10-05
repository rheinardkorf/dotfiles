#!/bin/bash
# Connection indicator: icon only. Green online, yellow slow, red offline.
sketchybar --add item ping right \
           --set ping script="$PLUGIN_DIR/ping.sh" \
                      update_freq=10 \
                      icon=󰓅 \
                      icon.color=$GREEN_ICON \
                      label.drawing=off \
           --subscribe ping system_woke
