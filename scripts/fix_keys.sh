#!/bin/bash

set -e

GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWAY_CONFIG="$HOME/.config/sway/config"

log_info "Fixing broken Windows key by changing Sway modifier to Alt (Mod1)..."
if [ -f "$SWAY_CONFIG" ]; then
    # Change the main modifier to Mod1 (Alt)
    sed -i 's/set $mod Mod4/set $mod Mod1/g' "$SWAY_CONFIG"
    
    # Remove the caps:super workaround if it was added previously
    sed -i '/xkb_options caps:super/d' "$SWAY_CONFIG"
    
    log_success "Changed Sway modifier to Alt (Mod1)!"
else
    log_info "Sway config not found at $SWAY_CONFIG. Assuming dotfiles are not fully installed yet."
fi

log_info "Applying terminal configurations (Zsh, Kitty, Starship)..."

# Apply Zsh
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
log_success "Linked ~/.zshrc"

# Change default shell to Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting Zsh as the default shell..."
    chsh -s "$(which zsh)" || log_info "Failed to change shell. You may need to run 'chsh -s \$(which zsh)' manually."
fi

# Apply Kitty
mkdir -p "$HOME/.config/kitty"
ln -sf "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
log_success "Linked Kitty terminal configuration"

# Apply Starship
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
log_success "Linked Starship prompt configuration"

log_success "All fixes applied!"
log_info "-> If you are in Sway, press CapsLock + Shift + C to reload your config."
log_info "-> Open a new terminal to see the Purple Zsh & Starship setup!"
