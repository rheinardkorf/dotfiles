#!/bin/bash
# A dim dot exactly where macOS draws its privacy indicator (orange mic,
# green camera, purple screen recording). When one is on, macOS's dot covers
# this one, so the spot "lights up". Static: no script.
sketchybar --add item privacy_dot right \
           --set privacy_dot icon=● \
                             icon.font="Hack Nerd Font:Regular:10.0" \
                             icon.color=$MOCHA_SURFACE1 \
                             icon.padding_left=0 \
                             icon.padding_right=0 \
                             label.drawing=off \
                             padding_left=3 \
                             padding_right=3
