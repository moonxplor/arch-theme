#!/bin/bash

# This script runs on system suspend and resume.
# 
# Background: The python3-validity driver for the Prometheus fingerprint 
# sensor must be fully restarted on resume to fix a hardware wedge issue.
# This restart takes about 6-8 seconds. 
# 
# Meanwhile, swaylock (started via before-sleep) is already running and 
# its PAM module (pam_fprint_grosshack) fails when the driver restarts.
# To fix this, we wait for the driver to finish starting, and if swaylock 
# is still active, we inject an 'Enter' keystroke. This causes swaylock 
# to fail the empty password attempt and loop back to the start of the 
# PAM stack, seamlessly re-activating the fingerprint reader!

if [ "$1" = "post" ]; then
    # Run in background to avoid blocking system resume
    (
        # Wait for python3-validity to finish uploading firmware
        sleep 8
        
        # Only inject keystroke if swaylock is actually running
        if pgrep -x swaylock > /dev/null; then
            for socket in /run/user/1000/wayland-*; do
                if [ -S "$socket" ]; then
                    WAYLAND_DISPLAY=$(basename "$socket")
                    su - dipak -c "XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=\"$WAYLAND_DISPLAY\" wtype -k Return"
                fi
            done
        fi
    ) &
fi
