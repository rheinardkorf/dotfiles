#!/usr/bin/env bash

# Source the colors.sh file to get color definitions
source "$CONFIG_DIR/colors.sh"

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

if [ "$1" = "$CURRENT_WORKSPACE" ]; then
    sketchybar --set $NAME background.color=$ACTIVE_COLOR 
else
    sketchybar --set $NAME background.color=$INACTIVE_COLOR 
fi