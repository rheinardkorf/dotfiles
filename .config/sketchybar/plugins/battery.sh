#!/bin/bash
# Battery level with Material Design icons (Nerd Font nf-md-battery*), in 10% steps.
# On power: the charging icon at the current level, in green.
# Otherwise: yellow at 30% or less, red at 15% or less.
source "$CONFIG_DIR/colors.sh"

LEVEL_ICONS=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)        # 0% (outline), 10% .. 90%, 100%
CHARGING_ICONS=(󰢟 󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)     # same steps, with a bolt

BATT="$(pmset -g batt)"
PERCENTAGE="$(grep -Eo '[0-9]+%' <<<"$BATT" | head -1 | tr -d %)"
[ -n "$PERCENTAGE" ] || exit 0   # no battery (desktop Mac)

STEP=$(( (PERCENTAGE + 5) / 10 ))   # nearest 10%
[ "$STEP" -gt 10 ] && STEP=10

if grep -q 'AC Power' <<<"$BATT"; then
  ICON=${CHARGING_ICONS[STEP]}; COLOR=$GREEN_ICON
else
  ICON=${LEVEL_ICONS[STEP]}
  if   [ "$PERCENTAGE" -le 15 ]; then COLOR=$RED_ICON
  elif [ "$PERCENTAGE" -le 30 ]; then COLOR=$YELLOW_ICON
  else                                COLOR=$WHITE
  fi
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
