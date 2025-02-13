#!/bin/bash

# Get hostname without .local suffix
HOSTNAME=$(scutil --get ComputerName)

# Set color based on hostname
case "$HOSTNAME" in
  "mantis")
    COLOR=0xff9d627d
    ;;
  "mando")
    COLOR=0xff629d82
    ;;
  *)
    COLOR=0xff61849e
    ;;
esac

# Update the label with hostname and add an icon, applying the conditional color
sketchybar --set $NAME icon=󰌢 \
                       label="$HOSTNAME" \
                       background.color=$COLOR \
                       icon.padding_right=0 \
                       icon.padding_left=5

