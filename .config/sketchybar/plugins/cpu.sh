#!/bin/bash

# Get CPU usage percentage - using a simpler top command
CPU_USAGE=$(top -l 1 | grep -E "^CPU" | grep -o '[0-9\.]*' | head -1)
CPU_USAGE=${CPU_USAGE%.*}  # Remove decimal places

# Set color based on CPU usage
if [ "$CPU_USAGE" -lt 30 ]; then
    COLOR=0xff9dd274  # Green for low usage
elif [ "$CPU_USAGE" -lt 70 ]; then
    COLOR=0xfff7af5c  # Orange for medium usage
else
    COLOR=0xffff6578  # Red for high usage
fi

sketchybar --set "$NAME" icon=󰻠 \
                         icon.color=$COLOR \
                         label="${CPU_USAGE}%" 