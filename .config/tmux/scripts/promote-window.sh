#!/usr/bin/env bash
# prefix P: move the current window into a session of its own and switch to it.
# The window keeps running (nothing restarts); it is only moved.
#   promote-window.sh <client_tty> <session_name> <window_id> <window_name> <pane_path> <session_windows>
set -euo pipefail
client="$1" session="$2" window_id="$3" window_name="$4" path="$5" count="$6"

if (( count <= 1 )); then
  tmux display-message -c "$client" "#[bold]$session#[nobold] has only this window; nothing to promote"
  exit 0
fi

# Name it <project>/<window>, like sesh names worktree sessions (unleash/fix-auth).
# tmux session names can't contain . or :
name="${session%%/*}/$window_name"
name="${name//[.:]/_}"
base="$name"; i=2
while tmux has-session -t "=$name" 2>/dev/null; do name="$base-$i"; i=$((i + 1)); done

placeholder="$(tmux new-session -d -P -F '#{window_id}' -s "$name" -c "$path")"
tmux move-window -s "$window_id" -t "=$name:"
tmux kill-window -t "$placeholder"
tmux move-window -r -t "=$session:"   # close the gap left in the original session
tmux switch-client -c "$client" -t "=$name"
tmux display-message -c "$client" "Promoted to session #[bold]$name#[nobold] (prefix Tab to go back to $session)"
