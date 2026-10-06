#!/usr/bin/env bash
# Delete the zsh history files of tmux sessions that no longer exist.
# Run by the session-closed and session-created hooks in tmux.conf; the files are
# made by ~/.config/zsh/configs/post/99-history.zsh as zsh-hist-<id>-<created>.
# Anything missed (a killed server) goes on the next run, or when macOS clears
# $TMPDIR on reboot.
set -uo pipefail

# A closing session's shells save their history as they exit, recreating the
# file; let them finish first (the hooks run this in the background)
sleep 2

dir="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}"
dir="${dir%/}"
live="$(tmux list-sessions -F '#{session_id}-#{session_created}' 2>/dev/null | tr -d '$')"

for f in "$dir"/zsh-hist-*; do
  [[ -e $f ]] || continue
  grep -qxF -- "${f##*/zsh-hist-}" <<<"$live" || rm -f -- "$f"
done
