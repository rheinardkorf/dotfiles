#!/bin/bash
# Jump to the Claude session that has been waiting longest: bring its terminal
# to the front and, in tmux, switch to its pane.
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-status"
TMUX_BIN="$(command -v tmux || echo /opt/homebrew/bin/tmux)"

f="$(ls -tr "$STATE_DIR"/* 2>/dev/null | head -1)"
[ -n "$f" ] || exit 0
pane="$(sed -n 's/^pane=//p' "$f")"
app="$(sed -n 's/^app=//p' "$f")"

app_of_pid() {  # the .app that owns a process (walks up the process tree)
  local pid=$1 path
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    path="$(ps -o comm= -p "$pid" 2>/dev/null)"
    case "$path" in *.app/Contents/*) printf '%s\n' "${path%%.app/*}.app"; return ;; esac
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  done
}

if [ -n "$pane" ]; then
  # The most recently active tmux client, and the terminal app it runs in
  read -r client client_pid < <("$TMUX_BIN" list-clients -F '#{client_activity} #{client_name} #{client_pid}' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -n "$client" ]; then
    app="$(app_of_pid "$client_pid")"
    "$TMUX_BIN" switch-client -c "$client" -t "$pane" 2>/dev/null
    "$TMUX_BIN" select-window -t "$pane" 2>/dev/null
    "$TMUX_BIN" select-pane -t "$pane" 2>/dev/null
  fi
fi
open -a "${app:-kitty}"   # Kitty if the terminal is unknown
