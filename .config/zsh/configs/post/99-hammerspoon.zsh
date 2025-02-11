export HAMMERSPOON_HOME="$HOME/.config/hammerspoon"

rm -rf "$HOME/.hammerspoon"

# Symlink $HOME/.hammerspoon to $HAMMERSPOON_HOME if the symlink doesn't exist.
if [ ! -L "$HOME/.hammerspoon" ]; then
   ln -s "$HAMMERSPOON_HOME" "$HOME/.hammerspoon"
fi
