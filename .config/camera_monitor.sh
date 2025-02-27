#!/bin/bash

# Launch with: 
# nohup ~/./.config/camera_monitor.sh >/dev/null 2>&1 &

LOG_FILE="$HOME/.camera_status"
echo "OFF" > "$LOG_FILE"  # Ensure the file starts as OFF

stdbuf -oL log stream --predicate 'subsystem == "com.apple.SkyLight"' --info | stdbuf -oL grep -E 'camera status 1|camera status 0' | while read -r line; do
    if echo "$line" | grep -q "camera status 1"; then
        echo "ON" > "$LOG_FILE"
    elif echo "$line" | grep -q "camera status 0"; then
        echo "OFF" > "$LOG_FILE"
    fi
done
