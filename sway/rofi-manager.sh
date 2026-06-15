#!/bin/bash
TYPE=$1

# Identify what is currently running
CURRENT=""
if pgrep -f "rofimoji" >/dev/null; then
    CURRENT="emoji"
elif pgrep -f "rofi -dmenu -p Clipboard" >/dev/null || pgrep -f "cliphist list" >/dev/null; then
    CURRENT="clipboard"
elif pgrep -x "rofi" >/dev/null; then
    CURRENT="drun"
fi

# Kill any existing rofi instances
pkill -x rofi
pkill -f rofimoji

# If the user pressed the hotkey for the menu that is ALREADY open,
# we just wanted to toggle it off, so we exit now.
if [ "$CURRENT" = "$TYPE" ]; then
    exit 0
fi

# Otherwise, open the newly requested menu
if [ "$TYPE" = "drun" ]; then
    rofi -show drun
elif [ "$TYPE" = "clipboard" ]; then
    mkdir -p ~/.cache/cliphist
    PINNED=$(cliphist -db-path ~/.cache/cliphist/pinned_db list 2>/dev/null | while IFS=$'\t' read -r id content; do
        printf "PIN_%s\t󰐃  %s\n" "$id" "$content"
    done)
    
    NORMAL=$(cliphist list 2>/dev/null | while IFS=$'\t' read -r id content; do
        if [[ "$content" == *"[[ binary data"* ]]; then
            printf "%s\t󰋩  %s\n" "$id" "$content"
        else
            printf "%s\t󰈔  %s\n" "$id" "$content"
        fi
    done)
    
    if [ -n "$PINNED" ]; then
        COMBINED=$(printf "%s\n%s" "$PINNED" "$NORMAL")
    else
        COMBINED="$NORMAL"
    fi

    set +e
    SELECTION=$(echo "$COMBINED" | grep -v "^$" | rofi -dmenu -p "Clipboard" -display-columns 2 -kb-custom-1 "Alt+p" -kb-custom-2 "Alt+c" -theme-str 'element { children: [ element-text ]; } entry { placeholder: "Search... (Alt+P: Pin, Alt+C: Clear)"; }')
    ROFI_EXIT=$?
    set -e

    if [ $ROFI_EXIT -eq 11 ]; then
        # Alt+c pressed: Clear standard history
        cliphist wipe
        exec ~/.config/sway/rofi-manager.sh clipboard
    elif [ -n "$SELECTION" ]; then
        REAL_SELECTION="${SELECTION#PIN_}"
        if [ $ROFI_EXIT -eq 10 ]; then
            if [[ "$SELECTION" == PIN_* ]]; then
                echo "$REAL_SELECTION" | cliphist -db-path ~/.cache/cliphist/pinned_db delete
            else
                echo "$REAL_SELECTION" | cliphist decode | wl-copy
                sleep 0.2
                wl-paste | cliphist -db-path ~/.cache/cliphist/pinned_db store
                echo "$REAL_SELECTION" | cliphist delete
            fi
            exec ~/.config/sway/rofi-manager.sh clipboard
        else
            if [[ "$SELECTION" == PIN_* ]]; then
                echo "$REAL_SELECTION" | cliphist -db-path ~/.cache/cliphist/pinned_db decode | wl-copy
            else
                echo "$REAL_SELECTION" | cliphist decode | wl-copy
            fi
        fi
    fi
elif [ "$TYPE" = "emoji" ]; then
    rofimoji --action clipboard --hidden-descriptions --selector-args "-theme ~/.config/rofi/rofimoji-theme.rasi"
fi
