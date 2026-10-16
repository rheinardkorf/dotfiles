#!/usr/bin/env sh
# panel's tmux keys. Load it from tmux.conf, through a plugin manager
# (set -g @plugin ...) or directly:
#
#   run-shell ~/.config/panel/panel.tmux
#
# Options, set before it loads (all optional):
#   @panel-bin       the panel engine      (default: bin/panel next to this file)
#   @panel-hud-key   prefix key: the HUD   (default: A; "off": no key)
#   @panel-key       prefix key: the panel session, built or repaired first
#                                          (default: off)

dir="$(cd "$(dirname "$0")" && pwd)"

opt() {
  v="$(tmux show-option -gqv "$1")"
  printf '%s' "${v:-$2}"
}

bin="$(opt @panel-bin "$dir/bin/panel")"
case $bin in "~/"*) bin="$HOME/${bin#"~/"}" ;; esac

hud_key="$(opt @panel-hud-key A)"
panel_key="$(opt @panel-key off)"

# the HUD over everything, borderless (esc closes it)
[ "$hud_key" = off ] || tmux bind-key "$hud_key" display-popup -E -B -w 100% -h 100% "'$bin' hud"
# panel up switches this client to the session once it's built
[ "$panel_key" = off ] || tmux bind-key "$panel_key" run-shell -b "'$bin' up"
