#!/bin/bash

# -- Catppuccin Mocha palette (same as Kitty, tmux, Neovim and the window borders) --
export MOCHA_ROSEWATER=0xfff5e0dc
export MOCHA_FLAMINGO=0xfff2cdcd
export MOCHA_PINK=0xfff5c2e7
export MOCHA_MAUVE=0xffcba6f7
export MOCHA_RED=0xfff38ba8
export MOCHA_MAROON=0xffeba0ac
export MOCHA_PEACH=0xfffab387
export MOCHA_YELLOW=0xfff9e2af
export MOCHA_GREEN=0xffa6e3a1
export MOCHA_TEAL=0xff94e2d5
export MOCHA_SAPPHIRE=0xff74c7ec
export MOCHA_BLUE=0xff89b4fa
export MOCHA_LAVENDER=0xffb4befe
export MOCHA_TEXT=0xffcdd6f4
export MOCHA_SUBTEXT0=0xffa6adc8
export MOCHA_OVERLAY0=0xff6c7086
export MOCHA_SURFACE1=0xff45475a
export MOCHA_SURFACE0=0xff313244
export MOCHA_BASE=0xff1e1e2e
export MOCHA_CRUST=0xff11111b

# Not Mocha: Claude's brand orange, for the Claude indicator
export CLAUDE_ORANGE=0xffd97757

# -- What the bar uses (scripts refer to these names) --
export WHITE=$MOCHA_TEXT                 # normal text and icons
export GREEN_ICON=$MOCHA_GREEN           # good / on
export YELLOW_ICON=$MOCHA_YELLOW         # slow / warning
export RED_ICON=$MOCHA_RED               # bad / high

export BAR_COLOR=0xd01e1e2e              # Mocha base, slightly see-through

# Per-machine colours, from ~/.config/machine-name (colours the workspace bullet)
export HOST_MANTIS_COLOR=$MOCHA_MAUVE
export HOST_MANDO_COLOR=$MOCHA_FLAMINGO
export HOST_OTHER_COLOR=$MOCHA_BLUE
