#!/bin/bash

# Define the available TLP power modes with Nerd Font icons
options="󰓅  performance\n󰾅  balanced\n󰌪  power-saver"

# Use rofi to display the options and get the user's selection
# We inject some basic custom styling to match the system's look
selected=$(echo -e "$options" | rofi -dmenu -i -p "Power Profile" \
    -theme-str 'window {width: 400px; border-radius: 12px; border: 2px; border-color: #39c5bb;}' \
    -theme-str 'listview {lines: 3;}' \
    -theme-str 'element { children: [ element-text ]; }' \
    -theme-str 'element selected {background-color: #39c5bb; text-color: #1a1b26;}')

# If the user selected a valid option, extract the profile name and apply it
if [ -n "$selected" ]; then
    # Strip the icon prefix to get just the profile name (e.g., 'performance')
    profile=$(echo "$selected" | awk '{print $2}')
    
    if [ -n "$profile" ]; then
        # We use kitty to prompt for sudo since tlp requires root permissions. We wrap it in bash so it stays open.
        kitty --class tlp_updater -T "Changing TLP to $profile" -e bash -c "sudo tlp $profile; echo ''; read -p 'Press Enter to close...'"
    fi
fi
