#!/bin/bash
if pgrep -x swayidle > /dev/null; then
    pkill -x swayidle
    notify-send -u low -t 2000 "Autosleep Disabled" "Screen will stay awake."
else
    ~/.config/sway/idle.sh &
    notify-send -u low -t 2000 "Autosleep Enabled" "Normal power management restored."
fi
