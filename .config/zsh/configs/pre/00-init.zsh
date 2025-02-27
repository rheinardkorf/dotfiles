# Initializes the config alias.
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

export EDITOR=nvim
export VISUAL=nvim

set -a  # Automatically export all variables
[ -f "$HOME/.env" ] && source "$HOME/.env"
set +a  # Stop auto-exporting

