#!/bin/bash

sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
                        icon=󰕾 \
           --subscribe volume volume_change 