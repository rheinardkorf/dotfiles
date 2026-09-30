#!/usr/bin/env bash
# Re-fit every window's pane layout to its window size.
# tmux-resurrect restores layouts at the size they were saved at; if the window
# is now a different size, panes can end up smaller than the window (blank
# space, odd drawing). Any size change makes tmux re-fit the layout, so nudge
# each window by one column, then un-pin it so it follows the client again.
# Runs after every resurrect restore (see tmux.conf); safe to run any time.
for w in $(tmux list-windows -a -F '#{window_id}'); do
  W=$(tmux display -p -t "$w" '#{window_width}')
  H=$(tmux display -p -t "$w" '#{window_height}')
  tmux resize-window -t "$w" -x $(( W > 2 ? W - 1 : W + 1 )) -y "$H"
  tmux set-option -wu -t "$w" window-size   # resize-window pins the size; undo that
  tmux resize-window -A -t "$w"
  tmux set-option -wu -t "$w" window-size
done
