export CURSOR_HOME="$HOME/.config/cursor"

# We don't want to use the default cursor dirs location.
# if [ -d "$HOME/.cursor" ]; then
   rm -rf "$HOME/.cursor"
#fi

# Symlink $HOME/.cursor to $CURSOR_HOME if the symlink doesn't exist.
if [ ! -L "$HOME/.cursor" ]; then
   ln -s "$CURSOR_HOME" "$HOME/.cursor"
fi