#!/usr/bin/env bash
# prefix a: arrange the session as  1 claude  2 zsh  ...  and go to claude.
#   claude-window.sh <session_id> <pane_current_path>
#
# claude: the window named "claude". Moved to the front if it's elsewhere, with
#   Claude restarted (--continue) if it was quit; or created there (in the current folder)
#   with Claude typed into a normal shell, so quitting Claude keeps the window.
#   Naming it at creation stops tmux renaming it to Claude's version number.
# zsh: a shell window right after it. tmux renames shell windows after what
#   runs in them (zsh -> nvim), so it's found by a window option (@role=zsh)
#   rather than its name; an untagged window named "zsh" is adopted, and if
#   there's none, one is created (without taking focus).
session="$1" path="$2"

windows() { tmux list-windows -t "$session" -F $'#{window_id}\t#{window_name}\t#{@role}'; }
renumber() { tmux move-window -r -t "$session"; }   # tmux only closes gaps itself when a window closes

# --- 1. claude, first -----------------------------------------------------------
claude="$(windows | awk -F'\t' '$2 == "claude" { print $1; exit }')"
if [[ -z "$claude" ]]; then
  claude="$(tmux new-window -P -F '#{window_id}' -b -t "$session:{start}" -n claude -c "$path")"
  tmux send-keys -t "$claude" claude Enter
else
  first="$(windows | head -1 | cut -f1)"
  if [[ "$claude" != "$first" ]]; then
    tmux move-window -b -s "$claude" -t "$first"
    renumber
  fi
  # Claude was quit (the window is back at a shell prompt): start it again,
  # continuing the most recent conversation in that folder. While Claude runs,
  # tmux reports its version number as the program instead. C-u clears
  # anything half-typed on the prompt first.
  case "$(tmux display -p -t "$claude" '#{pane_current_command}')" in
    zsh|bash|sh|fish) tmux send-keys -t "$claude" C-u 'claude --continue' Enter ;;
  esac
fi

# --- 2. zsh, second -------------------------------------------------------------
zsh="$(windows | awk -F'\t' '$3 == "zsh" { print $1; exit }')"
[[ -n "$zsh" ]] || zsh="$(windows | awk -F'\t' '$2 == "zsh" && $3 == "" { print $1; exit }')"
if [[ -z "$zsh" ]]; then
  zsh="$(tmux new-window -d -P -F '#{window_id}' -a -t "$claude" -c "$path")"
else
  second="$(windows | sed -n 2p | cut -f1)"
  if [[ "$zsh" != "$second" ]]; then
    tmux move-window -a -s "$zsh" -t "$claude"
    renumber
  fi
fi
tmux set-option -w -t "$zsh" @role zsh

tmux select-window -t "$claude"
