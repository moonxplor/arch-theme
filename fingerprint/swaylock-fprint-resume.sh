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
            SWAYLOCK_PID=$(pgrep -x swaylock | head -n1)
            SWAYLOCK_USER=$(ps -o user= -p "$SWAYLOCK_PID")
            SWAYLOCK_UID=$(id -u "$SWAYLOCK_USER")
            
            for socket in /run/user/$SWAYLOCK_UID/wayland-*; do
                if [ -S "$socket" ]; then
                    WAYLAND_DISPLAY=$(basename "$socket")
                    su - "$SWAYLOCK_USER" -c "XDG_RUNTIME_DIR=/run/user/$SWAYLOCK_UID WAYLAND_DISPLAY=\"$WAYLAND_DISPLAY\" wtype -k Return"
                fi
            done
        fi
    ) &
fi
