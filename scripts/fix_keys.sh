#!/bin/bash

set -e

GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWAY_CONFIG="$HOME/.config/sway/config"

log_info "Fixing broken Windows key..."
# Map Caps Lock to Super instead of using Alt, which avoids breaking their Alt clipboard shortcuts
if [ -f "$SWAY_CONFIG" ]; then
    if grep -q "caps:super" "$SWAY_CONFIG"; then
        log_info "Caps Lock is already mapped to Super in sway/config."
    else
        echo -e "\n# Fix for broken Windows key\ninput type:keyboard {\n    xkb_options caps:super\n}" >> "$SWAY_CONFIG"
        log_success "Mapped Caps Lock to Super in Sway! You can now use Caps Lock as your Windows/Mod key."
    fi
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
