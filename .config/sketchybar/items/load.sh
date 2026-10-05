#!/bin/bash
# CPU and GPU load, shown only while busy (e.g. a local AI model running).
# One script (plugins/load.sh, on the cpu item) updates both every 2 seconds.
# Right items are placed right to left, so gpu sits next to the time, cpu left of it.
for item in gpu cpu; do
  sketchybar --add item "$item" right \
             --set "$item" drawing=off \
                           background.drawing=off
done
# updates=on: keep running while hidden (SketchyBar skips hidden items otherwise)
sketchybar --set cpu icon=󰻠 update_freq=2 updates=on script="$PLUGIN_DIR/load.sh" \
           --set gpu icon=󰢮
