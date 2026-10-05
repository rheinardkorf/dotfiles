#!/bin/bash
# Claude Code sessions waiting for you (permission prompt or question), in any
# terminal. Hidden when none. Click: jump to the (longest) waiting one.
# Fed by the Claude hooks: ~/.config/tmux/scripts/claude-status.sh triggers claude_status.
sketchybar --add event claude_status \
           --add item claude left \
           --set claude drawing=off \
                        updates=on \
                        icon=󰚩 \
                        icon.color=$CLAUDE_ORANGE \
                        icon.padding_right=0 \
                        label.color=$CLAUDE_ORANGE \
                        label.padding_left=3 \
                        script="$PLUGIN_DIR/claude.sh" \
                        click_script="$PLUGIN_DIR/claude_click.sh" \
           --subscribe claude claude_status system_woke
