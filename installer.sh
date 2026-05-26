#!/usr/bin/env bash

set -euo pipefail

# ── Colors (Matching Jovial Palette) ──────────────────────────────────────────
PURPLE='\033[1;35m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
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

# ── Cleanup Handler (Ensures clean exits on Ctrl+C) ───────────────────────────
cleanup() {
    if [ -n "${SUDO_LOOP_PID+x}" ]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# ── Header ────────────────────────────────────────────────────────────────────
cat <<'EOF'
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)  melo-installer.
EOF
echo -e "\n${BLUE}Installing Meloworld rice...${RESET}\n"

# ── Pre-flight Checks ─────────────────────────────────────────────────────────
info "Asking for sudo password upfront to ensure smooth installation..."
sudo -v || error "Sudo permission is required to install system components."

# Keep sudo alive during the script execution safely
( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 10; done ) 2>/dev/null &
SUDO_LOOP_PID=$!

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
        if [ -d "$INSTALL_LOC" ]; then
            mkdir -p "$HOME/.config_backup"
            mv "$INSTALL_LOC" "${BACKUP_DIR}_repo_old"
        fi
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
        brightnessctl ghostty power-profiles-daemon papirus-icon-theme sddm
        ttf-jetbrains-mono-nerd grim slurp awww bibata-cursor-theme-bin eza
        zed zsh zsh-autosuggestions zsh-syntax-highlighting adw-gtk-theme zenity
        xdg-desktop-portal-wlr hypridle hyprlock cliphist wl-clipboard playerctl
        zoxide bat fd fzf ripgrep lazygit noto-fonts-emoji switcheroo-control
    )

    info "Checking for missing packages..."
    MISSING_PACKAGES=()
    for pkg in "${PACKAGES[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
        success "All dependencies are already satisfied.\n"
    else
        info "Installing: ${MISSING_PACKAGES[*]}"
        $PKGER -S --needed --noconfirm "${MISSING_PACKAGES[@]}" || error "Failed to install packages."
        success "Dependencies installed.\n"
    fi
else
    info "Skipped dependency installation.\n"
fi

# ── 3. Keyboard Configuration ─────────────────────────────────────────────────
info "Step 3: Keyboard Configuration"
if ask_permission "Configure keyboard layout for MangoWM?"; then
    # Attempt to detect the current system layout (defaults to 'us' if it fails)
    CURRENT_LAYOUT=$(localectl status 2>/dev/null | awk '/X11 Layout/ {print $3}' | head -n 1)
    CURRENT_LAYOUT=${CURRENT_LAYOUT:-us}

    echo -ne "${PURPLE}==> ${YELLOW}Enter your preferred keyboard layout (e.g., us, tr, de, fr) [default: ${CURRENT_LAYOUT}]: ${RESET}"
    read -r USER_LAYOUT
    USER_LAYOUT=${USER_LAYOUT:-$CURRENT_LAYOUT}

    MANGO_CONF="$INSTALL_LOC/mango/config.conf"

    if [ -f "$MANGO_CONF" ]; then
        sed -i "s/^xkb_rules_layout=.*/xkb_rules_layout=$USER_LAYOUT/" "$MANGO_CONF"
        success "Keyboard layout set to '$USER_LAYOUT' in MangoWM config.\n"
    else
        warn "MangoWM config file not found at $MANGO_CONF! Could not update layout.\n"
    fi
else
    info "Skipped keyboard configuration.\n"
fi

# ── 4. Targeted Symlinking ────────────────────────────────────────────────────
info "Step 4: Configurations"
if ask_permission "Symlink dotfiles to ~/.config?"; then
    for item in "${TARGETS[@]}"; do
        TARGET_PATH="$HOME/.config/$item"
        SRC_PATH="$INSTALL_LOC/$item"

        if [ -d "$SRC_PATH" ]; then
            if [ -L "$TARGET_PATH" ] && [ "$(readlink "$TARGET_PATH")" = "$SRC_PATH" ]; then
                info "Already linked: $item"
                continue
            fi

            if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
                mkdir -p "$BACKUP_DIR"
                mv "$TARGET_PATH" "$BACKUP_DIR/"
            fi

            ln -sf "$SRC_PATH" "$TARGET_PATH"
            find "$TARGET_PATH" -type f -name "*.sh" -exec chmod +x {} +
            success "Linked: $item"
        else
            warn "Source directory $SRC_PATH not found. Skipping."
        fi
    done

    # ── Wallpapers Copy ───────────────────────────────────────────────────────────
    info "Installing wallpapers..."

    WALLPAPER_SRC="$INSTALL_LOC/assets/wallpapers"
    WALLPAPER_DEST="$HOME/Pictures/Wallpapers/meloworld-wallpapers"

    if [ -d "$WALLPAPER_SRC" ]; then
        mkdir -p "$HOME/Pictures/Wallpapers"

        rm -rf "$WALLPAPER_DEST"
        cp -r "$WALLPAPER_SRC" "$WALLPAPER_DEST"

        success "Wallpapers installed to $WALLPAPER_DEST"
    else
        warn "Wallpaper source directory not found at $WALLPAPER_SRC"
    fi

    ZSHRC_TARGET="$HOME/.zshrc"
    ZSHRC_SRC="$INSTALL_LOC/.zshrc"
    if [ -f "$ZSHRC_SRC" ]; then
        if [ -L "$ZSHRC_TARGET" ] && [ "$(readlink "$ZSHRC_TARGET")" = "$ZSHRC_SRC" ]; then
            info "Already linked: .zshrc"
        else
            if [ -f "$ZSHRC_TARGET" ] || [ -L "$ZSHRC_TARGET" ]; then
                mkdir -p "$BACKUP_DIR"
                mv "$ZSHRC_TARGET" "$BACKUP_DIR/"
            fi
            ln -sf "$ZSHRC_SRC" "$ZSHRC_TARGET"
            success "Linked: .zshrc"
        fi
    fi
    echo ""
else
    info "Skipped configurations symlinking.\n"
fi

# ── 5. System & SDDM ──────────────────────────────────────────────────────────
info "Step 5: System Setup"

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
    sudo systemctl enable --now bluetooth power-profiles-daemon switcheroo-control

    gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

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

echo -e "\n${GREEN}Meloworld is ready! Please reboot your system to apply all changes. Also please read the usage tips from the github.${RESET}\n"
