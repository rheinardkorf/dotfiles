#!/bin/bash

sketchybar --add item hostname left \
           --set hostname \
                 script="$PLUGIN_DIR/hostname.sh"
