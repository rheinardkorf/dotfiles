# This machine's name (mando, mantis) for tools that keep per-machine config, such
# as muxdash. From ~/.config/machine-name, since macOS hostnames drift (mando-2);
# without the file, muxdash falls back to the hostname itself
if [[ -r ~/.config/machine-name ]]; then
  export MUXDASH_MACHINE="$(<~/.config/machine-name)"
  export PANEL_MACHINE="$MUXDASH_MACHINE"   # panel, until it's gone
fi
