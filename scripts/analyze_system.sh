#!/bin/bash
# analyze_system.sh - Discover current system state for dotfiles migration

set -e

# --- Colors ---
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_val()  { echo -e "  - ${YELLOW}$1${RESET}: $2"; }
log_warn() { echo -e "${YELLOW}[!] $1${RESET}"; }

echo "=========================================="
echo "    System Analysis for Migration         "
echo "=========================================="

# 1. OS Info
log_info "Operating System"
if [ -f /etc/os-release ]; then
    source /etc/os-release
    log_val "OS Name" "$PRETTY_NAME"
else
    log_val "OS Name" "Unknown"
fi
log_val "Kernel" "$(uname -r)"

# 2. Hardware Info
log_info "Hardware"
log_val "Host" "$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
log_val "CPU" "$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
log_val "RAM" "$(free -h | awk '/^Mem:/ {print $2}')"
GPU=$(lspci | grep -i vga | awk -F: '{print $3}' | xargs)
log_val "GPU" "$GPU"

# Display Resolution
DISPLAY_RES=""
if command -v xdpyinfo >/dev/null 2>&1; then
    DISPLAY_RES=$(xdpyinfo | awk '/dimensions/{print $2}')
elif [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card*-*; do
        if [ -e "$card/status" ] && grep -q '^connected$' "$card/status"; then
            mode=$(cat "$card/modes" 2>/dev/null | head -n 1)
            if [ -n "$mode" ]; then
                DISPLAY_RES="${DISPLAY_RES}${mode} "
            fi
        fi
    done
fi
log_val "Display" "${DISPLAY_RES:-Unknown}"

# Peripherals
if lsusb | grep -qi "fingerprint"; then
    log_val "Fingerprint Sensor" "Detected"
else
    log_val "Fingerprint Sensor" "Not detected"
fi

if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
    log_val "Battery" "Detected"
else
    log_val "Battery" "Not detected"
fi

# 3. Desktop Environment & Services
log_info "Desktop Environment"
log_val "Current DE" "${XDG_CURRENT_DESKTOP:-Unknown}"
log_val "Current Session" "${XDG_SESSION_TYPE:-Unknown}"

# Check for Display Manager
DM="Unknown"
for dm in sddm gdm lightdm ly greetd lemurs; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        DM="$dm (enabled)"
        break
    fi
done
log_val "Display Manager" "$DM"

# 4. KDE Plasma Detection
log_info "KDE Plasma Status"
KDE_PKGS=$(pacman -Qq | grep -E "^plasma-desktop|^plasma-workspace" || true)
if [ -n "$KDE_PKGS" ]; then
    log_warn "KDE Plasma packages detected. Migration should disable SDDM and backup configs."
else
    log_val "KDE Plasma" "Not installed"
fi

# 5. Configurations to Backup
log_info "Configurations to Backup"
BACKUP_TARGETS=("$HOME/.config/kdeglobals" "$HOME/.config/plasmashellrc" "$HOME/.config/kwinrc")
for target in "${BACKUP_TARGETS[@]}"; do
    if [ -e "$target" ]; then
        log_val "Needs backup" "$target"
    fi
done

echo "=========================================="
echo "Analysis complete. Use this info to guide the installation."
echo "=========================================="
