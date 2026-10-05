#!/usr/bin/env bash
# Called by Claude Code hooks (~/.claude/settings.json) for every Claude Code
# session, in tmux or not.
#
#   claude-status.sh waiting        needs you (permission prompt, question)   󰚩
#   claude-status.sh done           finished its turn                         ✓
#   claude-status.sh resume         clear 󰚩 once work continues (e.g. after approving)
#   claude-status.sh clear          remove the marker (you replied / session ended)
#
# Two outputs:
#   - SketchyBar (any terminal): one file per waiting session in $STATE_DIR;
#     the claude item shows how many are waiting, and clicking it jumps there.
#   - tmux (only inside tmux): marks the window (@claude) for the tmux bar.
#
# Never fails, so it can't disrupt Claude.
input="$(cat)"   # hook payload (JSON) on stdin
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-status"
TMUX_BIN="$(command -v tmux || echo /opt/homebrew/bin/tmux)"
JQ_BIN="$(command -v jq || echo /opt/homebrew/bin/jq)"
SKETCHYBAR_BIN="$(command -v sketchybar || echo /opt/homebrew/bin/sketchybar)"

# Idle reminders ("waiting for your input" after a minute) aren't a real
# request; the ✓ from finishing already covers that.
if [[ "${1:-}" == waiting && ( "$input" == *idle_prompt* || "$input" == *"waiting for your input"* ) ]]; then
  exit 0
fi

session="$("$JQ_BIN" -r '.session_id // empty' <<<"$input" 2>/dev/null)"
[[ -n "$session" ]] || session="pane-${TMUX_PANE:-$PPID}"
state_file="$STATE_DIR/$session"

# The terminal app this session runs in (used outside tmux): walk up the
# process tree to the first process inside an .app bundle.
terminal_app() {
  local pid=$PPID path
  while [[ -n "$pid" && "$pid" -gt 1 ]]; do
    path="$(ps -o comm= -p "$pid" 2>/dev/null)"
    [[ "$path" == *.app/Contents/* ]] && { printf '%s\n' "${path%%.app/*}.app"; return; }
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  done
}

# --- SketchyBar: a file per waiting session -----------------------------------
# Only nudge SketchyBar when something changed (PostToolUse fires constantly).
case "${1:-}" in
  waiting)
    mkdir -p "$STATE_DIR"
    {
      printf 'pane=%s\n' "${TMUX_PANE:-}"
      printf 'app=%s\n' "$([[ -z "${TMUX_PANE:-}" ]] && terminal_app)"
      printf 'cwd=%s\n' "$("$JQ_BIN" -r '.cwd // empty' <<<"$input" 2>/dev/null)"
    } > "$state_file"
    "$SKETCHYBAR_BIN" --trigger claude_status >/dev/null 2>&1 ;;
  done|resume|clear)
    if [[ -e "$state_file" ]]; then
      rm -f "$state_file"
      "$SKETCHYBAR_BIN" --trigger claude_status >/dev/null 2>&1
    fi ;;
esac

# --- tmux: mark the window ------------------------------------------------------
[[ -n "${TMUX_PANE:-}" ]] || exit 0
case "${1:-}" in
  waiting)
    "$TMUX_BIN" set-option -w -t "$TMUX_PANE" @claude waiting ;;
  done)
    "$TMUX_BIN" set-option -w -t "$TMUX_PANE" @claude done ;;
  resume)
    [[ "$("$TMUX_BIN" show-options -wqv -t "$TMUX_PANE" @claude)" == waiting ]] &&
      "$TMUX_BIN" set-option -wu -t "$TMUX_PANE" @claude ;;
  clear)
    "$TMUX_BIN" set-option -wu -t "$TMUX_PANE" @claude ;;
esac
# Redraw status bars now rather than at the next status-interval tick
"$TMUX_BIN" list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r c; do
  "$TMUX_BIN" refresh-client -S -t "$c" 2>/dev/null
done
exit 0
