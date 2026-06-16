#!/bin/bash
if pgrep -x swayidle > /dev/null; then
    pkill -x swayidle
    notify-send -u low -t 2000 "Autosleep Disabled" "Screen will stay awake."
else
    swayidle -w \
         timeout 60 'brightnessctl -s set 10' resume 'brightnessctl -r' \
         timeout 120 'swaylock -f -c 1A1B26' \
         timeout 300 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
         timeout 600 'systemctl suspend' \
         before-sleep 'swaylock -f -c 1A1B26' &
    notify-send -u low -t 2000 "Autosleep Enabled" "Normal power management restored."
fi
