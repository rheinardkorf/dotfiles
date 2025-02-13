#!/bin/bash

sketchybar --add item ping right \
           --set ping script="$PLUGIN_DIR/ping.sh" \
                     update_freq=10 \
                     icon.color=0xff9dd274 \