#!/usr/bin/env bash
# Status block: git branch and status of the active pane's folder (via gitmux).
# Nothing is shown outside a git repo.   git-block.sh <path>
out="$(gitmux -cfg "$HOME/.gitmux.conf" "$1" 2>/dev/null)"
out="${out//#\[fg=default,bg=default\]/}"   # gitmux's trailing reset would break the block's background
exec "$(dirname "$0")/tmux-block.sh" @thm_teal "󰊢 " "$out"
