#!/bin/bash

sketchybar --add item gpu right \
           --set gpu script="$PLUGIN_DIR/gpu.sh" \
                    update_freq=1 