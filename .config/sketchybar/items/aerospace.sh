# Get the current workspace
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

# Get all workspaces
ALL_WORKSPACES=$(aerospace list-workspaces --all)

# Add all workspaces to the bar
for sid in $ALL_WORKSPACES; do

    sketchybar --add item space.label.$sid left \
        --subscribe space.label.$sid aerospace_workspace_change aerospace_window_change \
        --set space.label.$sid \
        background.corner_radius=25 \
        background.height=11 \
        update_freq=5 \
        label="$sid" \
        label.color=$WHITE_TRANSPARENT \
        background.color=0x00000000 \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.padding_left=2 \
        label.padding_right=2 \
        label.font.size=8 \
        background.padding_left=3 \
        background.padding_right=3 \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

sketchybar --trigger aerospace_window_change