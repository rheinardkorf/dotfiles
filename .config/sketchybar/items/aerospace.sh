# Get the current workspace
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

# Get all workspaces
ALL_WORKSPACES=$(aerospace list-workspaces --all)

# Add all workspaces to the bar
for sid in $ALL_WORKSPACES; do

    sketchybar --add item space.label.$sid left \
        --set space.label.$sid \
        label="$sid" \
        background.color=0x00000000 \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.padding_left=5 \
        label.padding_right=5 \
        label.font.size=8 \
        background.padding_left=0 \
        background.padding_right=0 \
        click_script="aerospace workspace $sid"

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
    WINDOWS=$(aerospace list-windows --json --workspace $sid)

    # Initialize arrays for tracking unique apps
    seen_apps=""
    seen_ids=""
    window_ids=""

    # Debug logging
    while read -r window; do
        window_id=$(echo "$window" | jq -r '."window-id"')
        app_name=$(echo "$window" | jq -r '."app-name"')

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
                click_script="aerospace workspace $sid"
        fi
    done < <(echo "$WINDOWS" | jq -c '.[]')

    # Create new bracket
    sketchybar --add bracket space.$sid space.label.$sid $window_ids \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
        background.color=$INACTIVE_COLOR \
        background.corner_radius=0 \
        background.height=20 \
        background.drawing=on \
        icon.padding_left=3 \
        icon.padding_right=3 \
        label.padding_left=5 \
        label.padding_right=5 \
        background.padding_left=3 \
        background.padding_right=3 \
        label="$sid" \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done
