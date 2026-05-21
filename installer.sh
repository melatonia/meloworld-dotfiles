#!/usr/bin/env bash

set -euo pipefail

# ── Colors (Matching Jovial Palette) ──────────────────────────────────────────
PURPLE='\033[1;35m'
GREEN='\033[1;32m'
YELLOW='\033[1;228m'
BLUE='\033[1;157m'
RED='\033[1;31m'
RESET='\033[0m'

# ── Paths & Variables ─────────────────────────────────────────────────────────
REPO_NAME="meloworld-dotfiles"
INSTALL_LOC="$HOME/.config/$REPO_NAME"
BACKUP_DIR="$HOME/.config_backup/$(date +%Y%m%d_%H%M%S)"
TARGETS=("quickshell" "mango" "ghostty" "hypr" "rofi" "zed")

# ── Helper Functions ──────────────────────────────────────────────────────────
info() { echo -e "${BLUE}==>${RESET} $1"; }
success() { echo -e "${GREEN}==>${RESET} $1"; }
warn() { echo -e "${YELLOW}==>${RESET} $1"; }
error() { echo -e "${RED}==> ERROR:${RESET} $1"; exit 1; }

ask_permission() {
    echo -ne "${PURPLE}==> ${YELLOW}$1 [y/N]: ${RESET}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then return 0; else return 1; fi
}

# ── Header ────────────────────────────────────────────────────────────────────
cat <<'EOF'
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)  melo-installer.
EOF
echo -e "\n${BLUE}Installing Meloworld rice...${RESET}\n"

# ── Pre-flight Checks ─────────────────────────────────────────────────────────
# Cache sudo credentials upfront
info "Asking for sudo password upfront to ensure smooth installation..."
sudo -v || error "Sudo permission is required to install system components."

# Keep sudo alive during the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Detect AUR helper
if command -v paru >/dev/null 2>&1; then
    PKGER="paru"
elif command -v yay >/dev/null 2>&1; then
    PKGER="yay"
else
    error "Neither 'paru' nor 'yay' was found. Please install an AUR helper first."
fi

# ── 1. Repository Migration ───────────────────────────────────────────────────
info "Step 1: Permanent Placement"
if ask_permission "Move dotfiles to $INSTALL_LOC?"; then
    CURRENT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    if [ "$CURRENT_DIR" != "$INSTALL_LOC" ]; then
        mkdir -p "$HOME/.config"
        [ -d "$INSTALL_LOC" ] && mv "$INSTALL_LOC" "${BACKUP_DIR}_repo_old"
        cp -r "$CURRENT_DIR" "$INSTALL_LOC"
        success "Migration successful to $INSTALL_LOC\n"
    else
        info "Repository is already in place.\n"
    fi
else
    info "Skipped migration.\n"
fi

# ── 2. Dependencies ───────────────────────────────────────────────────────────
info "Step 2: Dependencies"
if ask_permission "Install required packages?"; then
    PACKAGES=(
        mangowm quickshell pipewire pipewire-pulse wireplumber bluez bluez-utils
        brightnessctl ghostty power-profiles-daemon polkit-gnome
        ttf-jetbrains-mono-nerd rofi-wayland rofimoji grim slurp awww
        bibata-cursor-theme-bin papirus-icon-theme zed zsh zsh-autosuggestions
        zsh-syntax-highlighting eza sddm adw-gtk-theme xdg-desktop-portal-wlr
        hypridle hyprlock cliphist wl-clipboard playerctl zoxide bat fd ripgrep
        lazygit
    )
    $PKGER -S --needed --noconfirm "${PACKAGES[@]}"
    success "Dependencies installed.\n"
else
    info "Skipped dependency installation.\n"
fi

# ── 3. Targeted Symlinking ────────────────────────────────────────────────────
info "Step 3: Configurations"
if ask_permission "Symlink dotfiles to ~/.config?"; then
    for item in "${TARGETS[@]}"; do
        if [ -d "$INSTALL_LOC/$item" ]; then
            if [ -e "$HOME/.config/$item" ]; then
                mkdir -p "$BACKUP_DIR"
                mv "$HOME/.config/$item" "$BACKUP_DIR/"
            fi
            ln -sf "$INSTALL_LOC/$item" "$HOME/.config/$item"
            find "$HOME/.config/$item" -type f -name "*.sh" -exec chmod +x {} +
            success "Linked: $item"
        else
            warn "Source directory $INSTALL_LOC/$item not found. Skipping."
        fi
    done

    if [ -f "$INSTALL_LOC/.zshrc" ]; then
        [ -f "$HOME/.zshrc" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.zshrc" "$BACKUP_DIR/"
        ln -sf "$INSTALL_LOC/.zshrc" "$HOME/.zshrc"
        success "Linked: .zshrc"
    fi
    echo ""
else
    info "Skipped configurations symlinking.\n"
fi

# ── 4. System & SDDM ──────────────────────────────────────────────────────────
info "Step 4: System Setup"

if ask_permission "Enable SDDM (and disable other display managers)?"; then
    sudo systemctl disable gdm lightdm ly 2>/dev/null || true
    sudo systemctl enable sddm
    success "SDDM enabled."
fi

if ask_permission "Install and configure SDDM theme files?"; then
    sudo mkdir -p /usr/share/sddm/themes/
    sudo cp -r "$INSTALL_LOC/meloworld-sddm" /usr/share/sddm/themes/

    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nCurrent=meloworld-sddm" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
    success "Meloworld SDDM theme installed and configured."
fi

if ask_permission "Apply final preferences & set Zsh as default shell?"; then
    sudo systemctl enable --now bluetooth power-profiles-daemon

    gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

    # Switch shell to Zsh to activate history and plugin settings
    if [[ "$SHELL" != */zsh ]]; then
        if command -v zsh >/dev/null 2>&1; then
            sudo chsh -s "$(which zsh)" "$USER"
            success "Default shell changed to Zsh."
        else
            warn "Zsh is not installed, cannot change default shell."
        fi
    else
        info "Zsh is already the default shell."
    fi
fi

echo -e "\n${GREEN}Meloworld is ready! Please reboot your system to apply all changes.${RESET}\n"
