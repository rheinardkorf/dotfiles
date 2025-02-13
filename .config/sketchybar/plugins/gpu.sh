#!/bin/bash

# Get GPU usage using powermetrics
# Note: You will need to run this as sudo, which will require you to set passwordless sudo for your user.
#
# 1. Run the following command to set passwordless sudo for your user:
# sudo visudo
# 
# 2. Add the following line to the bottom of the file:
# your_username ALL=(ALL) NOPASSWD: /usr/bin/powermetrics
#
# You can find your username by running:
# whoami
#
GPU_USAGE=$(sudo powermetrics --samplers gpu_power -i 5000 -n1 | grep "GPU HW active residency" | awk '{print $5}' | tr -d '%')
# Convert GPU_USAGE to integer by removing decimal places
GPU_USAGE_INTEGER=${GPU_USAGE%.*}

if [ -n "$GPU_USAGE_INTEGER" ]; then
    # Set color based on GPU usage
    if [ "$GPU_USAGE_INTEGER" -lt 30 ]; then
        COLOR=0xff9dd274  # Green for low usage
    elif [ "$GPU_USAGE_INTEGER" -lt 70 ]; then
        COLOR=0xfff7af5c  # Orange for medium usage
    else
        COLOR=0xffff6578  # Red for high usage
    fi

    sketchybar --set "$NAME" icon=󰢮 \
                             icon.color=$COLOR \
                             label="${GPU_USAGE_INTEGER}%"
else
    sketchybar --set "$NAME" icon=󰢮 \
                             icon.color=0xff9dd274 \
                             label="N/A"
fi 