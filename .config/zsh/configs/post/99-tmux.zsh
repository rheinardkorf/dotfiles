# tmux + sesh helpers
# t        pick a session/project     t <dir>   session for <dir> (e.g. t .)
t() {
  if [[ $# -gt 0 ]]; then
    sesh connect "${1:A}"
  else
    sesh picker -i
  fi
}
alias ta='tmux attach || tmux new -s main'
bindkey -s '^f' 't\n'    # Ctrl-f from any shell opens the picker
