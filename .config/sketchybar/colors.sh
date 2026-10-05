#!/bin/bash

# -- Catppuccin Mocha palette (same as Kitty, tmux, Neovim and the window borders) --
export MOCHA_ROSEWATER=0xfff5e0dc
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

# -- What the bar uses (scripts refer to these names) --
export TRANSPARENT=0x00000000
export WHITE=$MOCHA_TEXT                 # normal text and icons
export WHITE_TRANSPARENT=$MOCHA_SUBTEXT0 # dimmer text (inactive workspaces)
export DARK_TEXT=$MOCHA_CRUST            # text on coloured backgrounds
export GREEN_ICON=$MOCHA_GREEN           # good / on
export ORANGE_ICON=$MOCHA_PEACH          # medium
export RED_ICON=$MOCHA_RED               # bad / high

export BAR_COLOR=0xd01e1e2e              # Mocha base, slightly see-through
export ITEM_BG_COLOR=0xd0313244          # Mocha surface0
export ACCENT_COLOR=$MOCHA_MAUVE
export ACTIVE_COLOR=$MOCHA_MAUVE         # focused workspace (tmux marks its current window in mauve too)
export INACTIVE_COLOR=0xc0313244         # other workspaces

# Per-machine badge colours (plugins/hostname.sh)
export HOST_MANTIS_COLOR=$MOCHA_MAROON
export HOST_MANDO_COLOR=$MOCHA_TEAL
export HOST_OTHER_COLOR=$MOCHA_BLUE

# -- Previous "Rheinard" scheme, before Catppuccin --
# export WHITE=0xffffffff
# export WHITE_TRANSPARENT=0xd0ffffff
# export GREEN_ICON=0xff9dd274
# export RED_ICON=0xffff6578
# export BAR_COLOR=0xd0101314
# export ITEM_BG_COLOR=0xd0353c3f
# export ACCENT_COLOR=0xaa394671
# export ACTIVE_COLOR=0xff6c7db5
# export INACTIVE_COLOR=0xc0353c3f

# -- Teal Scheme --
# export BAR_COLOR=0xff001f30
# export ITEM_BG_COLOR=0xff003547
# export ACCENT_COLOR=0xff2cf9ed

# -- Gray Scheme --
# export BAR_COLOR=0xff101314
# export ITEM_BG_COLOR=0xff353c3f
# export ACCENT_COLOR=0xffffffff

# -- Purple Scheme --
# export BAR_COLOR=0xff140c42
# export ITEM_BG_COLOR=0xff2b1c84
# export ACCENT_COLOR=0xffeb46f9

# -- Red Scheme ---
# export BAR_COLOR=0xff23090e
# export ITEM_BG_COLOR=0xff591221
# export ACCENT_COLOR=0xffff2453

# -- Blue Scheme --- 
# export BAR_COLOR=0xff021254
# export ITEM_BG_COLOR=0xff093aa8
# export ACCENT_COLOR=0xff15bdf9

# -- Green Scheme --
# export BAR_COLOR=0xff003315
# export ITEM_BG_COLOR=0xff008c39
# export ACCENT_COLOR=0xff1dfca1


# -- Orange Scheme --
# export BAR_COLOR=0xff381c02
# export ITEM_BG_COLOR=0xff99440a
# export ACCENT_COLOR=0xfff97716

# -- Yellow Scheme --
# export BAR_COLOR=0xff2d2b02
# export ITEM_BG_COLOR=0xff8e7e0a
# export ACCENT_COLOR=0xfff7fc17
