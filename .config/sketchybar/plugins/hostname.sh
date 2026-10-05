#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Machine name from ~/.config/machine-name (the MDM controls the computer name),
# falling back to the system name if that file doesn't exist
HOSTNAME=$(head -n1 "$HOME/.config/machine-name" 2>/dev/null | tr -d '[:space:]')
[ -n "$HOSTNAME" ] || HOSTNAME=$(scutil --get ComputerName)

# Set color based on hostname
case "$HOSTNAME" in
  "mantis")
    COLOR=$HOST_MANTIS_COLOR
    ;;
  "mando")
    COLOR=$HOST_MANDO_COLOR
    ;;
  *)
    COLOR=$HOST_OTHER_COLOR
    ;;
esac

# Update the label with hostname and add an icon, applying the conditional color
sketchybar --set $NAME icon=󰌢 \
                       label="$HOSTNAME" \
                       background.color=$COLOR \
                       icon.color=$DARK_TEXT \
                       label.color=$DARK_TEXT \
                       icon.padding_right=0 \
                       icon.padding_left=5

