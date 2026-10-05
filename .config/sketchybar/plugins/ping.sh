#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Ping Google's DNS server and get the response time
PING_RESULT=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null)
if [ $? -eq 0 ]; then
    LATENCY=$(echo "$PING_RESULT" | awk -F '/' 'END {print $5}')
    LATENCY=${LATENCY%.*}  # Remove decimal places
    
    # Set color based on latency
    if [ "$LATENCY" -lt 50 ]; then
        COLOR=$GREEN_ICON   # Green for good latency
    elif [ "$LATENCY" -lt 100 ]; then
        COLOR=$ORANGE_ICON  # Orange for medium latency
    else
        COLOR=$RED_ICON     # Red-pink for high latency
    fi
    
    sketchybar --set "$NAME" icon=󰓅 \
                             icon.color=$COLOR \
                             label="${LATENCY}ms"
else
    sketchybar --set "$NAME" icon=󰓅 \
                             icon.color=$RED_ICON \
                             label="Offline"
fi 