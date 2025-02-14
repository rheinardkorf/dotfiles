#!/bin/bash

# Get Aerospace windows mapping using indexed arrays
aerospace_windows=()
aerospace_workspaces=()

while IFS=" " read -r WINDOW_ID WORKSPACE; do
    aerospace_windows+=("$WINDOW_ID")
    aerospace_workspaces+=("$WORKSPACE")
done < <(aerospace list-windows --all --format "%{window-id} %{app-name} %{workspace}" --json | jq -r '.[] | select(.["window-id"] and .workspace) | "\(.["window-id"]) \(.workspace)"')

# Get Sketchybar window mappings using indexed arrays
sketchybar_windows=()
sketchybar_workspaces=()
current_workspace=""

while IFS= read -r line; do
    if [[ $line == space.label.* ]]; then
        current_workspace="${line#space.label.}"
    elif [[ $line == window.* && -n $current_workspace ]]; then
        window_id="${line#window.}"
        sketchybar_windows+=("$window_id")
        sketchybar_workspaces+=("$current_workspace")
    fi
done < <(sketchybar --query bar | jq -r '.items[] | select(startswith("space.") or startswith("window."))')

# Compare and move windows only if needed
for i in "${!aerospace_windows[@]}"; do
    window_id="${aerospace_windows[$i]}"
    aerospace_workspace="${aerospace_workspaces[$i]}"

    # Find the corresponding workspace in Sketchybar
    sketchybar_workspace="none"
    for j in "${!sketchybar_windows[@]}"; do
        if [[ "${sketchybar_windows[$j]}" == "$window_id" ]]; then
            sketchybar_workspace="${sketchybar_workspaces[$j]}"
            break
        fi
    done

    if [[ "$aerospace_workspace" != "$sketchybar_workspace" ]]; then
        sketchybar --move "window.$window_id" after "space.label.$aerospace_workspace"
        sketchybar --set window.$window_id click_script="aerospace workspace $aerospace_workspace"
    fi
done
