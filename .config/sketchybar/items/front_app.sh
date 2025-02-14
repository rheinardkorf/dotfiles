#!/bin/bash
sketchybar --add item front_app.separator left \
    --set front_app.separator label="󰄾" \
    icon.drawing=off \
    background.drawing=off \
    label.font="Hack Nerd Font:Bold:12.0" \
    label.color=$WHITE \
    label.padding_right=0 \
    label.padding_left=5

sketchybar --add item front_app left \
    --set front_app \
    icon.color=$WHITE \
    icon.font="sketchybar-app-font:Regular:12.0" \
    label.color=$WHITE \
    script="$PLUGIN_DIR/front_app.sh" \
    --subscribe front_app front_app_switched
