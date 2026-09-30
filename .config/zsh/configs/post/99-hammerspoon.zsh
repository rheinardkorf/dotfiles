export HAMMERSPOON_HOME="$HOME/.config/hammerspoon"

# Make ~/.hammerspoon a symlink to $HAMMERSPOON_HOME. Safe to run from many
# shells at once (e.g. a tmux restore):
#   - does nothing when the link is already correct (the common case)
#   - never deletes a real ~/.hammerspoon folder; it only warns
#   - ln -n replaces an existing link instead of creating a new one *inside* the
#     linked folder (the old rm -rf + ln -s raced and left hammerspoon/hammerspoon)
if [[ "$(readlink "$HOME/.hammerspoon")" != "$HAMMERSPOON_HOME" ]]; then
  if [[ -e "$HOME/.hammerspoon" && ! -L "$HOME/.hammerspoon" ]]; then
    echo "~/.hammerspoon is a real folder, not a link to $HAMMERSPOON_HOME; leaving it alone" >&2
  else
    ln -sfn "$HAMMERSPOON_HOME" "$HOME/.hammerspoon"
  fi
fi
