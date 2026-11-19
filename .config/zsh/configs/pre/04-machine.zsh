# This machine's name (mando, mantis) for tools that keep per-machine config, such
# as muxdash. From ~/.config/machine-name, since macOS hostnames drift (mando-2);
# without the file, muxdash falls back to the hostname itself
[[ -r ~/.config/machine-name ]] && export MUXDASH_MACHINE="$(<~/.config/machine-name)"
