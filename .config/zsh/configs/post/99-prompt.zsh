# Inside tmux, drop git info from the prompt: the tmux bar's git block (and the
# sesh session name) already show it. Outside tmux, the full prompt stays.
#   in tmux:   ➜ flow
#   outside:   ➜ flow git:(main) ✗
if [[ -n "$TMUX" ]]; then
  PROMPT="${PROMPT/' $(git_prompt_info)'/ }"   # quoted: ( ) are literal, not a pattern group
fi
