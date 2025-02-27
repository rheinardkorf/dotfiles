#!/bin/bash

sketchybar --add item camera e \
           --set camera script="$PLUGIN_DIR/camera_status.sh" \
                     update_freq=5


