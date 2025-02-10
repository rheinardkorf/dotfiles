export CURSOR_HOME="$HOME/.config/cursor"

if [ -d "$HOME/.cursor" ]; then
    rm -rf "$HOME/.cursor"
fi

if [ ! -d "$CURSOR_HOME" ]; then
    ln -s ~/.config/cursor ~/.cursor
fi
