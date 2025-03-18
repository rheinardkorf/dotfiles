#!/bin/bash

# Launch with: 
# nohup ~/./.config/mic_monitor.sh >/dev/null 2>&1 &

MIC_LOG_FILE="$HOME/.mic_status"
echo "OFF" > "$MIC_LOG_FILE"

# Monitor microphone only
stdbuf -oL log stream --predicate 'process == "coreaudiod"' --info | stdbuf -oL grep -E 'Report client.*running: (yes|no)' | while read -r line; do
    if echo "$line" | grep -q "running: yes"; then
        echo "ON" > "$MIC_LOG_FILE"
    elif echo "$line" | grep -q "running: no"; then
        echo "OFF" > "$MIC_LOG_FILE"
    fi
done
