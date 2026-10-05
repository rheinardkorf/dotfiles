#!/bin/bash
# Count Claude Code sessions waiting for you; show the item only if any.
# One file per waiting session, written by ~/.config/tmux/scripts/claude-status.sh.
source "$CONFIG_DIR/colors.sh"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-status"
TMUX_BIN="$(command -v tmux || echo /opt/homebrew/bin/tmux)"

# Forget sessions that went away without clearing: older than 12 hours, or a
# tmux pane that no longer exists.
find "$STATE_DIR" -type f -mmin +720 -delete 2>/dev/null
live_panes="$("$TMUX_BIN" list-panes -a -F '#{pane_id}' 2>/dev/null)"
count=0
for f in "$STATE_DIR"/*; do
  [ -f "$f" ] || continue
  pane="$(sed -n 's/^pane=//p' "$f")"
  if [ -n "$pane" ] && ! grep -qxF "$pane" <<<"$live_panes"; then
    rm -f "$f"; continue
  fi
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
elif [ "$count" -eq 1 ]; then
  sketchybar --set "$NAME" drawing=on label.drawing=off      # one: just the icon
else
  sketchybar --set "$NAME" drawing=on label.drawing=on label="$count"
fi
