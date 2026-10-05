#!/usr/bin/env bash

# Source the colors.sh file to get color definitions
source "$CONFIG_DIR/colors.sh"

EVENT_NAME="$SENDER" # Sketchybar sets the event name in this variable
WORKSPACE=$1

# Handle different events
case "$EVENT_NAME" in
"aerospace_workspace_change" | "forced")
    if [ "$WORKSPACE" = "$(aerospace list-workspaces --focused)" ]; then
        sketchybar --set space.label.$WORKSPACE background.color=$ACTIVE_COLOR label.color=$DARK_TEXT
    else
        sketchybar --set space.label.$WORKSPACE background.color=$INACTIVE_COLOR label.color=$WHITE_TRANSPARENT
    fi
    ;;
"aerospace_window_change" | "routine")
    # One icon per app per workspace: two Brave windows in a workspace show one
    # Brave icon; Brave in workspaces 1 and 3 shows one icon in each.
    # Icons are items named app.<workspace>.<app>. Every workspace runs this
    # script on each window change and syncs only its own icons.
    PREFIX="app.$WORKSPACE."
    BAR_ITEMS=$(sketchybar --query bar | jq -r '.items[]')

    # Remove per-window icons left over from the previous version of this script
    for item in $(grep '^window\.' <<<"$BAR_ITEMS"); do
        sketchybar --remove "$item" 2>/dev/null
    done

    # Distinct apps with windows in this workspace
    WANTED=""
    while IFS= read -r app_name; do
        [ -n "$app_name" ] || continue
        item="$PREFIX$(printf '%s' "$app_name" | tr -c 'A-Za-z0-9' '_')"
        WANTED="$WANTED$item"$'\n'

        if ! grep -qxF "$item" <<<"$BAR_ITEMS"; then
            sketchybar --add item "$item" left \
                --set "$item" \
                icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app_name")" \
                icon.font="sketchybar-app-font:Regular:14.0" \
                icon.padding_left=0 \
                icon.padding_right=0 \
                label.padding_left=0 \
                label.padding_right=0 \
                icon.color=$WHITE_TRANSPARENT \
                background.color=$TRANSPARENT \
                background.padding_left=0 \
                background.padding_right=0 \
                click_script="aerospace workspace $WORKSPACE"
            sketchybar --move "$item" after "space.label.$WORKSPACE"
        fi
    done < <(aerospace list-windows --workspace "$WORKSPACE" --format '%{app-name}' | sort -u)

    # Remove icons for apps that no longer have a window in this workspace
    awk -v p="$PREFIX" 'index($0, p) == 1' <<<"$BAR_ITEMS" | while IFS= read -r item; do
        grep -qxF "$item" <<<"$WANTED" || sketchybar --remove "$item"
    done
    ;;
*)
    echo "Unknown event: $EVENT_NAME"
    ;;
esac
