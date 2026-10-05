#!/bin/bash
# Show the focused AeroSpace workspace as a numbered circle (runs on
# aerospace_workspace_change, which aerospace.toml triggers on every switch).
# Glyphs: Nerd Font Material icons numeric-1-circle .. numeric-9-circle (U+F0CA0, every 2nd).
GLYPHS=(󰲠 󰲢 󰲤 󰲦 󰲨 󰲪 󰲬 󰲮 󰲰)
WS=$(aerospace list-workspaces --focused)
if [[ "$WS" =~ ^[1-9]$ ]]; then
    sketchybar --set "$NAME" icon="${GLYPHS[WS-1]}"
else
    sketchybar --set "$NAME" icon="$WS"   # a named workspace: plain text
fi
