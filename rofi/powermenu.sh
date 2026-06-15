#!/bin/bash

shutdown="  Shutdown"
reboot="󰜉  Reboot"
suspend="󰒲  Suspend"
logout="󰗽  Logout"
lock="󰌾  Lock"

# Check if rofi is already running
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

options="$shutdown\n$reboot\n$suspend\n$logout\n$lock"

chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -theme ~/.config/rofi/powermenu.rasi)"

case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $suspend)
        systemctl suspend
        ;;
    $logout)
        swaymsg exit
        ;;
    $lock)
        swaylock -f -c 1A1B26
        ;;
esac
