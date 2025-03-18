#!/bin/bash

source "$CONFIG_DIR/colors.sh"

STATUS_FILE="$HOME/.mic_status"

if [[ -f "$STATUS_FILE" ]]; then
    STATUS=$(cat "$STATUS_FILE" | tr -d '[:space:]') # Remove extra spaces

    if [[ "$STATUS" == "ON" ]]; then
        COLOR=$GREEN_ICON
    else
        #COLOR=$RED_ICON
        COLOR=$ITEM_BG_COLOR
    fi
fi

sketchybar --set $NAME icon="" \
                       icon.padding_right=0 \
                       icon.padding_left=0 \
                       icon.color=$COLOR \
                       background.color=0x00000000


