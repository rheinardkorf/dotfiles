# Shell history lasts as long as the tmux session: its panes share it, and it is
# deleted when the session closes (~/.config/tmux/scripts/prune-history.sh).
# Outside tmux it stays in memory and is gone when the shell exits.
# Commands worth keeping go in ~/.config/zsh/commands.txt via `keep` (99-keep.zsh).
#
# Must load after oh-my-zsh: its lib/history.zsh sets HISTFILE and SAVEHIST when
# they are unset or small, which would undo anything set before it.

HISTSIZE=1000

_session_hist=
if [[ -n $TMUX ]]; then
  # session_created as well as session_id: ids restart at $0 with a new tmux server
  _session_hist="$(tmux display -p -t "$TMUX_PANE" '#{session_id}-#{session_created}' 2>/dev/null)"
fi

if [[ -n $_session_hist ]]; then
  HISTFILE="${TMPDIR%/}/zsh-hist-${_session_hist//\$/}"
  SAVEHIST=1000
else
  unset HISTFILE
  SAVEHIST=0
fi
unset _session_hist
