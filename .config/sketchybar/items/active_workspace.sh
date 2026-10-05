#!/bin/bash
# The focused AeroSpace workspace as a single numbered bullet.
# Replaces the full workspace list (items/aerospace.sh, no longer loaded).
# Its colour says which Mac this is (colors.sh: HOST_*_COLOR).
case "$(head -n1 "$HOME/.config/machine-name" 2>/dev/null | tr -d '[:space:]')" in
  mantis) BULLET_COLOR=$HOST_MANTIS_COLOR ;;
  mando)  BULLET_COLOR=$HOST_MANDO_COLOR ;;
  *)      BULLET_COLOR=$HOST_OTHER_COLOR ;;
esac

sketchybar --add item active_workspace left \
    --subscribe active_workspace aerospace_workspace_change \
    --set active_workspace \
    icon.font="Hack Nerd Font:Regular:16.0" \
    icon.color=$BULLET_COLOR \
    icon.padding_left=0 \
    icon.padding_right=0 \
    label.drawing=off \
    script="$PLUGIN_DIR/active_workspace.sh"
