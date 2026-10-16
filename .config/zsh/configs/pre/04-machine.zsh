# This machine's name (mando, mantis) for tools that keep per-machine config, such
# as panel. From ~/.config/machine-name, since macOS hostnames drift (mando-2);
# without the file, panel falls back to the hostname itself
[[ -r ~/.config/machine-name ]] && export PANEL_MACHINE="$(<~/.config/machine-name)"
