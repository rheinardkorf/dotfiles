#!/usr/bin/env bash
# Print a square status block in the catppuccin style:  █<icon> <text>█
#   tmux-block.sh <colour-option> <icon> <text>
# Prints nothing when <text> is empty, so a block only shows when it has
# something to say. Colours come from the loaded catppuccin palette (@thm_*).
colour="$1" icon="$2" text="$3"
[[ -n "$text" ]] || exit 0
opt() { tmux show -gqv "$1"; }
c="$(opt "$colour")" crust="$(opt @thm_crust)" fg="$(opt @thm_fg)" s0="$(opt @thm_surface_0)"
printf '#[fg=%s]█#[fg=%s,bg=%s]%s#[fg=%s,bg=%s] %s#[fg=%s,bg=default]█#[default] ' \
  "$c" "$crust" "$c" "$icon" "$fg" "$s0" "$text" "$s0"
