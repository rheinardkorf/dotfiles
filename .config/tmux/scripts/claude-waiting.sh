#!/usr/bin/env bash
# Status-bar helper: names the other sessions that have a Claude waiting for you.
#   claude-waiting.sh <current-session>          classic style
#   claude-waiting.sh <current-session> block    catppuccin-style block
names="$(tmux list-windows -a -F '#{session_name}	#{@claude}' 2>/dev/null |
  awk -F'\t' -v cur="$1" '$2 == "waiting" && $1 != cur && !seen[$1]++ { printf "%s%s", (n++ ? " " : ""), $1 }')"
[[ -n "$names" ]] || exit 0
if [[ "${2:-}" == block ]]; then
  exec "$(dirname "$0")/tmux-block.sh" @thm_yellow "󰂞 " "$names"
fi
printf '#[fg=colour0,bg=colour3,bold] 🔔 %s #[default] ' "$names"
