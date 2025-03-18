#!/bin/bash

sketchybar --add item microphone e \
           --set microphone script="$PLUGIN_DIR/mic_status.sh" \
                     update_freq=5


