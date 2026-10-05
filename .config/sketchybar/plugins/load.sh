#!/bin/bash
# Show CPU and GPU only while busy, with their load:
#   CPU appears from 40% and hides below 25% (normal use bursts up to ~25%)
#   GPU appears from 75% and hides below 60% (macOS counts drawing the screen
#   as GPU use, so normal use already reads 20-45%)
#   Either change only sticks after 3 readings in a row (6 seconds), so short
#   spikes never make an icon pop up or vanish.
#   colour: green under 50%, yellow under 80%, red from 80%
# CPU: all processes' CPU from ps, divided by the number of cores.
# GPU: macOS's own utilisation figure (ioreg; no sudo), averaged over the last
#      3 readings because it jumps around from moment to moment.

source "$CONFIG_DIR/colors.sh"

STATE="${TMPDIR:-/tmp}/sketchybar-load"

cpu=$(ps -A -o %cpu= | awk -v n="$(sysctl -n hw.ncpu)" '{ s += $1 } END { printf "%d", s / n }')

gpu_now=$(ioreg -r -d 1 -w 0 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)
gpu_hist="$(tail -n 2 "$STATE.gpu" 2>/dev/null)"$'\n'"${gpu_now:-0}"
printf '%s\n' "$gpu_hist" | sed '/^$/d' > "$STATE.gpu"
gpu=$(awk '{ s += $1; n++ } END { printf "%d", n ? s / n : 0 }' "$STATE.gpu")

READINGS=3   # in a row before showing or hiding

update() {  # update <item> <percent> <show at> <hide below>
  local item=$1 pct=$2 show_at=$3 hide_below=$4
  local shown_file="$STATE.$1.shown" streak_file="$STATE.$1.streak" streak color
  streak=$(cat "$streak_file" 2>/dev/null || echo 0)

  if [ -e "$shown_file" ]; then
    # showing: count readings below the hide threshold
    if [ "$pct" -lt "$hide_below" ]; then streak=$((streak + 1)); else streak=0; fi
    if [ "$streak" -ge "$READINGS" ]; then
      rm -f "$shown_file"; echo 0 > "$streak_file"
      sketchybar --set "$item" drawing=off
      return
    fi
  else
    # hidden: count readings at or above the show threshold
    if [ "$pct" -ge "$show_at" ]; then streak=$((streak + 1)); else streak=0; fi
    if [ "$streak" -lt "$READINGS" ]; then echo "$streak" > "$streak_file"; return; fi
    touch "$shown_file"; streak=0
  fi
  echo "$streak" > "$streak_file"

  if   [ "$pct" -lt 50 ]; then color=$GREEN_ICON
  elif [ "$pct" -lt 80 ]; then color=$YELLOW_ICON
  else                         color=$RED_ICON
  fi
  sketchybar --set "$item" drawing=on icon.color="$color" label="${pct}%" label.color="$color"
}

update cpu "$cpu" 40 25
update gpu "$gpu" 75 60
