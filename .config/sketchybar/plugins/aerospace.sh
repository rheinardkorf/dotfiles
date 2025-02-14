#!/usr/bin/env bash

# Source the colors.sh file to get color definitions
source "$CONFIG_DIR/colors.sh"

EVENT_NAME="$SENDER" # Sketchybar sets the event name in this variable
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)
WORKSPACE=$1

SKETCHYBAR_WINDOWS=$(sketchybar --query bar | jq -r '.items[] | select(startswith("window."))')
AEROSPACE_WINDOWS=$(aerospace list-windows --json --all |jq -r '.[] | "window.\(.["window-id"])"')
MISSING_WINDOWS=$(echo "$SKETCHYBAR_WINDOWS" | grep -F -x -v -f <(echo "$AEROSPACE_WINDOWS"))

# Handle different events
case "$EVENT_NAME" in
"aerospace_workspace_change" | "forced")
    if [ "$WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
        sketchybar --set space.label.$WORKSPACE background.color=$ACTIVE_COLOR
    else
        sketchybar --set space.label.$WORKSPACE background.color=$INACTIVE_COLOR
    fi
    ;;
"aerospace_window_change" | "routine")
    # Delete existing window items
    for window in $MISSING_WINDOWS; do
        sketchybar --remove "$window"
    done

    # Get all windows on the current workspace
    # Returns a JSON array of windows with the following format:
    # [
    #     {
    #         "window-id": 1,
    #         "window-title": "Window 1",
    #         "app-name": "App 1"
    #     },
    #     {
    #         "window-id": 2,
    #         "window-title": "Window 2",
    #         "app-name": "App 2"
    #     }
    # ]
    WINDOWS=$(aerospace list-windows --json --workspace $WORKSPACE)

    # Initialize arrays for tracking unique apps
    seen_apps=""
    seen_ids=""
    window_ids=""

    # Debug logging
    while read -r window; do
        window_id=$(echo "$window" | jq -r '."window-id"')
        app_name=$(echo "$window" | jq -r '."app-name"')

        # Skip if window is already in sketchybar
        if echo "$SKETCHYBAR_WINDOWS" | grep -q "window.$window_id"; then
            continue
        fi

        # Check if we've seen this app name before
        if ! echo "$seen_apps" | grep -q "^$app_name$"; then
            # Add to our tracking variables
            seen_apps="$seen_apps$app_name\n"
            seen_ids="$seen_ids$window_id\n"

            # Add to window_ids with proper spacing
            if [ -z "$window_ids" ]; then
                window_ids="window.$window_id"
            else
                window_ids="$window_ids window.$window_id"
            fi

            sketchybar --remove window.$window_id
            sketchybar --add item window.$window_id left \
                --set window.$window_id \
                background.color=0x00000000 \
                icon=$($CONFIG_DIR/plugins/icon_map_fn.sh "$app_name") \
                icon.font="sketchybar-app-font:Regular:12.0" \
                icon.padding_left=0 \
                icon.padding_right=0 \
                label.padding_left=5 \
                label.padding_right=5 \
                background.padding_left=0 \
                background.padding_right=0 \
                click_script="aerospace workspace $WORKSPACE"

            sketchybar --move window.$window_id after space.label.$WORKSPACE
        fi
    done < <(echo "$WINDOWS" | jq -c '.[]')

    # Add logic to update window icons
    ;;
*)
    echo "Unknown event: $EVENT_NAME"
    ;;
esac