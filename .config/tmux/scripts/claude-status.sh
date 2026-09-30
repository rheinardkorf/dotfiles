#!/usr/bin/env bash
# Called by Claude Code hooks (~/.claude/settings.json) to mark the tmux window
# a Claude session runs in. The marker is shown in the tmux status bar.
#
#   claude-status.sh waiting        needs you (permission prompt, question)   🔔
#   claude-status.sh done           finished its turn                         ✓
#   claude-status.sh resume         clear 🔔 once work continues (e.g. after approving)
#   claude-status.sh clear          remove the marker (you replied / session ended)
#
# Does nothing outside tmux. Never fails, so it can't disrupt Claude.
input="$(cat)"   # hook payload (JSON) on stdin
[[ -n "${TMUX_PANE:-}" ]] || exit 0
TMUX_BIN="$(command -v tmux || echo /opt/homebrew/bin/tmux)"

case "${1:-}" in
  waiting)
    # Idle reminders ("waiting for your input" after a minute) aren't a real
    # request; the ✓ from finishing already covers that.
    [[ "$input" == *idle_prompt* || "$input" == *"waiting for your input"* ]] && exit 0
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
