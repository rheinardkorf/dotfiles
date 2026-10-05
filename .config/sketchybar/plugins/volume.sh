#!/bin/bash
# Output volume. On volume_change SketchyBar passes the level in $INFO; at
# startup (and on wake) it's read from macOS. Muted shows dimmed.
source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)')"
fi
MUTED="$(osascript -e 'output muted of (get volume settings)')"

case "$VOLUME" in
  [6-9][0-9]|100) ICON="󰕾" ;;
  [3-5][0-9])     ICON="󰖀" ;;
  [1-9]|[1-2][0-9]) ICON="󰕿" ;;
  *)              ICON="󰖁" ;;
esac

if [ "$MUTED" = "true" ]; then
  ICON="󰖁"; COLOR=$MOCHA_OVERLAY0
else
  COLOR=$WHITE
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOLUME}%" label.color="$COLOR"
