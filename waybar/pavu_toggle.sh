#!/bin/bash

# If pavucontrol is already running, kill it (toggle behavior for the Waybar button)
if pgrep -x pavucontrol > /dev/null; then
    pkill -x pavucontrol
    exit 0
fi

# Launch pavucontrol in the background
pavucontrol &
PAVU_PID=$!

# Use swaymsg to listen to window focus events.
# We unbuffer jq so it processes events in real-time.
swaymsg -t subscribe -m '["window"]' | jq --unbuffered '.change' | while read -r event; do
    if [[ "$event" == '"focus"' ]]; then
        # When focus changes, check which app is currently focused
        focused_app=$(swaymsg -t get_tree | jq -r '.. | select(.type? == "con" and .focused? == true) | .app_id')
        
        # If the newly focused app is NOT pavucontrol, kill pavucontrol and exit the script
        if [[ "$focused_app" != "org.pulseaudio.pavucontrol" ]]; then
            pkill -x pavucontrol
            break
        fi
    fi
done
