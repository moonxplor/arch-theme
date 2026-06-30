#!/bin/bash

set -e

# --- Colors ---
GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
log_warn() { echo -e "\e[33m[!] $1${RESET}"; }
log_error() { echo -e "${RED}[!] $1${RESET}"; }

prompt_yn() {
    while true; do
        read -p "$(echo -e "${BLUE}[?] $1 [Y/n] ${RESET}")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) return 0;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# --- Pre-flight Checks ---
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. Use your normal user account."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Welcome to the Purple Arch Dotfiles Installer!"
sleep 1

# --- 0. System Analysis ---
log_info "Analyzing target system..."
if [ -x "$DOTFILES_DIR/scripts/analyze_system.sh" ]; then
    bash "$DOTFILES_DIR/scripts/analyze_system.sh"
else
    log_warn "analyze_system.sh not found, skipping analysis."
fi
sleep 2

# --- 1. Pacman Configurations & Repositories ---
log_info "Configuring Pacman parallel downloads and repositories..."

# Enable Parallel Downloads if not already enabled
if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
    log_info "Enabling Parallel Downloads..."
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
fi

# Enable multilib repo if not already enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    log_info "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
fi

# Enable Chaotic AUR if not already enabled
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Setting up Chaotic AUR..."
    # 1. Receive key
    KEY="3056513E7043D7A13B266D9614E7517E4F707477"
    for server in keyserver.ubuntu.com hkps://keyserver.ubuntu.com hkps://keys.openpgp.org hkp://pgp.mit.edu; do
        log_info "Trying to fetch key from $server..."
        if sudo pacman-key --recv-key "$KEY" --keyserver "$server"; then
            log_success "Key fetched successfully!"
            break
        fi
        log_warn "Failed to fetch from $server, trying next..."
    done
    sudo pacman-key --lsign-key "$KEY" || true
    # 2. Install keyring and mirrorlist
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    # 3. Append to pacman.conf
    sudo bash -c 'cat <<EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
    sudo pacman -Sy
    log_success "Chaotic AUR enabled!"
fi

# --- 2. Install AUR Helper (yay) ---
if ! command -v yay &> /dev/null; then
    log_info "yay not found. Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    TMP_YAY_DIR=$(mktemp -d -t yay-bin-XXXXXX)
    git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY_DIR"
    cd "$TMP_YAY_DIR"
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf "$TMP_YAY_DIR"
    log_success "yay installed!"
else
    log_success "yay is already installed."
fi

# --- 3. Install Packages ---
log_info "Installing dependencies..."
PACKAGES=(
    # Core Environment
    "swayfx" "swaybg" "waybar" "rofi-wayland" "kitty" "thunar"
    # Display Manager
    "ly"
    # Audio Stack
    "pipewire" "wireplumber" "pipewire-pulse" "libpulse" "pavucontrol"
    # System/UX Utilities
    "swayidle" "swaylock" "brightnessctl" "swaync" "wlogout" "polkit-kde-agent" "network-manager-applet" "sway-audio-idle-inhibit-git" "xdg-desktop-portal" "xdg-desktop-portal-wlr" "jq" "autotiling" "grim" "slurp" "swappy" "playerctl" "imagemagick"
    # Clipboard & Emoji
    "wl-clipboard" "cliphist" "rofimoji"
    # Power & Auth
    "tlp" "gnome-keyring"
    # Default Apps & Shell
    "zen-browser-bin" "zed" "neovim" "zathura" "zathura-pdf-mupdf" "imv" "mpv" "xarchiver" "vesktop" "snapshot" "zsh" "starship" "zoxide" "eza" "bat" "fzf"
    # Theming & Fonts
    "adw-gtk-theme" "ttf-ibm-plex" "ttf-firacode-nerd" "ttf-joypixels" "librsvg" "npm" "kvantum" "kvantum-qt5"
)
yay -S --needed --noconfirm "${PACKAGES[@]}"
log_success "Dependencies installed!"

# --- 4. Install Zinit ---
if [ ! -d "$HOME/.local/share/zinit" ]; then
    if prompt_yn "Install Zinit plugin manager (Recommended for ZSH)?"; then
        log_info "Installing Zinit plugin manager..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        log_success "Zinit installed!"
    else
        log_info "Skipping Zinit..."
    fi
fi

# --- 5. Directory Management ---
log_info "Creating required directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/Pictures/wallpapers"
log_success "Directories created!"

# --- 6. Symlinking Configurations ---
log_info "Backing up and symlinking configs..."

backup_and_symlink() {
    local SRC="$1"
    local DEST="$2"
    
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        if [ ! -L "$DEST" ]; then
            local BAK="${DEST}.bak"
            if [ -e "$BAK" ]; then
                BAK="${DEST}_$(date +%Y%m%d_%H%M%S).bak"
            fi
            log_info "Backing up existing $DEST to $BAK"
            mv "$DEST" "$BAK"
        else
            rm "$DEST"
        fi
    fi
    ln -sf "$SRC" "$DEST"
}

# Config directories
for config in sway swaylock waybar kitty rofi swaync wlogout btop environment.d qt5ct qt6ct tlpui gtk-3.0 gtk-4.0 fontconfig Thunar xfce4 Kvantum swappy; do
    backup_and_symlink "$DOTFILES_DIR/$config" "$HOME/.config/$config"
done

log_info "Backing up KDE configurations if present..."
for kde_conf in kdeglobals plasmashellrc kwinrc; do
    if [ -f "$HOME/.config/$kde_conf" ]; then
        mv "$HOME/.config/$kde_conf" "$HOME/.config/${kde_conf}.bak"
        log_info "Backed up KDE config: $kde_conf"
    fi
done

# Independent dotfiles
backup_and_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
backup_and_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
backup_and_symlink "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"
log_success "Configs successfully linked!"

# --- Set Zsh as default shell ---
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting Zsh as your default shell..."
    chsh -s "$(which zsh)" || log_warn "Could not change shell automatically. Run 'chsh -s \$(which zsh)' manually."
    log_success "Default shell set to Zsh!"
else
    log_info "Zsh is already the default shell."
fi

# --- 7. Install Wallpaper & Generate Bookmarks ---
log_info "Installing wallpapers..."
TARGET_WP="/home/moonxplor/Pictures/Wallpaper/IMG_2565.PNG"
if [ -f "$HOME/Pictures/wallpapers/active_wallpaper.png" ]; then
    log_success "Wallpapers already installed."
else
    if [ -f "$TARGET_WP" ]; then
        log_info "Generating theme wallpapers using $TARGET_WP..."
        if ! command -v magick &> /dev/null; then
            sudo pacman -S --needed --noconfirm imagemagick jq
        fi
        bash "$DOTFILES_DIR/scripts/apply_frosted_glass.sh" "$TARGET_WP" "$HOME/Pictures/wallpapers/active_wallpaper.png"
    else
        log_warn "Target wallpaper $TARGET_WP not found. Falling back to default."
        cp "$DOTFILES_DIR/wallpapers/satisfaction_waybar_blur.png" "$HOME/Pictures/wallpapers/active_wallpaper.png"
        cp "$DOTFILES_DIR/wallpapers/satisfaction_waybar_blur_lock.png" "$HOME/Pictures/wallpapers/active_wallpaper_lock.png"
    fi
    log_success "Wallpapers installed!"
fi

log_info "Generating file manager bookmarks..."
cat << EOF > "$DOTFILES_DIR/gtk-3.0/bookmarks"
file://$HOME/Pictures
file://$HOME/code
file://$HOME/Music
file://$HOME/Documents
file://$HOME/Videos
file://$HOME/Downloads
EOF

# --- 8. Custom Icons & Desktop Launchers ---
log_info "Symlinking custom icons and desktop files..."
backup_and_symlink "$DOTFILES_DIR/icons/YAMIS-enlarged" "$HOME/.local/share/icons/YAMIS-enlarged"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/YAMIS-enlarged" || true
log_success "Custom icons linked!"

if [ -f "$DOTFILES_DIR/etc/tlp.conf" ]; then
    if diff -q "/etc/tlp.conf" "$DOTFILES_DIR/etc/tlp.conf" &>/dev/null; then
        log_info "TLP power management configuration is already up to date."
    else
        if prompt_yn "Restore TLP Power Management Configuration?"; then
            log_info "Restoring TLP power management system config..."
            sudo cp "$DOTFILES_DIR/etc/tlp.conf" "/etc/tlp.conf"
            sudo chmod 644 "/etc/tlp.conf"
            log_success "TLP restored!"
        fi
    fi
fi

log_info "Setting up Ly display manager..."

# Disable old display managers
for dm in ly greetd sddm gdm lightdm plasmalogin lemurs; do
    sudo systemctl disable "$dm.service" 2>/dev/null || true
done

# Enable ly if not already enabled
if ! systemctl is-enabled --quiet ly.service 2>/dev/null; then
    sudo systemctl enable -f ly.service
    log_success "Ly display manager enabled!"
else
    log_info "Ly display manager is already enabled."
fi

# Install global utility scripts
log_info "Installing global system utilities..."
sudo ln -sf "$DOTFILES_DIR/scripts/togglekb" /usr/local/bin/togglekb
log_success "System scripts and configs installed!"

# --- 10. Systemd Services ---
log_info "Enabling systemd user services..."
backup_and_symlink "$DOTFILES_DIR/systemd/user/sway-hw-notify.service" "$HOME/.config/systemd/user/sway-hw-notify.service"
systemctl --user daemon-reload
systemctl --user enable --now sway-hw-notify.service
log_success "Systemd services enabled!"

log_success "Installation Complete!"
log_info "NOTE: After reboot, you will be greeted by the Lemurs display manager."
log_info "Use the left/right arrow keys to select 'sway' (SwayFX) before entering your password."
log_info "Reboot or log out to enjoy your pristine Sway setup!"
