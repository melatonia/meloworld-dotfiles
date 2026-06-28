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
TARGETS=("quickshell" "niri" "hypr" "kitty" "vesktop" "zed" "zathura")

# ── Helper Functions ──────────────────────────────────────────────────────────
info() { echo -e "${BLUE}==>${RESET} $1"; }
success() { echo -e "${GREEN}==>${RESET} $1"; }
warn() { echo -e "${YELLOW}==>${RESET} $1"; }
error() {
    echo -e "${RED}==> ERROR:${RESET} $1" >&2
    exit 1
}

# Returns 0 (true) for y/Y, 1 (false) otherwise.
# The surrounding 'if' absorbs the non-zero return so set -e is not triggered.
ask_permission() {
    echo -ne "${PURPLE}==> ${YELLOW}$1 [y/N]: ${RESET}"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Creates a unique, timestamped backup directory only when first needed.
# Subsequent calls within the same script run reuse the same directory.
_BACKUP_DIR=""
get_backup_dir() {
    if [[ -z "$_BACKUP_DIR" ]]; then
        _BACKUP_DIR="$HOME/.config_backup/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$_BACKUP_DIR"
    fi
    echo "$_BACKUP_DIR"
}

# ── Cleanup Handler (Ensures clean exits on Ctrl+C) ───────────────────────────
cleanup() {
    if [[ -n "${SUDO_LOOP_PID+x}" ]]; then
        kill "$SUDO_LOOP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# ── Header ────────────────────────────────────────────────────────────────────
cat <<'EOF'
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)  melo-installer · arch
EOF
echo -e "\n${BLUE}Installing Meloworld rice on Arch Linux...${RESET}\n"

# ── Pre-flight Checks ─────────────────────────────────────────────────────────
info "Asking for sudo password upfront to ensure smooth installation..."
sudo -v || error "Sudo permission is required to install system components."

# Keep sudo alive during script execution
(while kill -0 "$$" 2>/dev/null; do
    sudo -n true
    sleep 10
done) 2>/dev/null &
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
    CURRENT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    if [[ "$CURRENT_DIR" != "$INSTALL_LOC" ]]; then
        mkdir -p "$HOME/.config"
        if [[ -d "$INSTALL_LOC" ]]; then
            mv "$INSTALL_LOC" "$(get_backup_dir)/${REPO_NAME}_old"
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
        niri quickshell pipewire pipewire-pulse wireplumber bluez bluez-utils
        brightnessctl kitty power-profiles-daemon papirus-icon-theme sddm
        ttf-jetbrains-mono-nerd grim slurp bibata-cursor-theme-bin eza
        zed zsh zsh-autosuggestions zsh-syntax-highlighting adw-gtk-theme zenity
        xdg-desktop-portal-wlr cliphist wl-clipboard playerctl
        zoxide bat fd fzf ripgrep lazygit noto-fonts-emoji switcheroo-control glow
        unzip awww mpvpaper hypridle xwayland-satellite
    )

    info "Checking for missing packages..."
    MISSING_PACKAGES=()
    for pkg in "${PACKAGES[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [[ ${#MISSING_PACKAGES[@]} -eq 0 ]]; then
        success "All dependencies are already satisfied.\n"
    else
        info "Installing: ${MISSING_PACKAGES[*]}"
        "$PKGER" -S --needed --noconfirm "${MISSING_PACKAGES[@]}" || error "Failed to install packages."
        success "Dependencies installed.\n"
    fi
else
    info "Skipped dependency installation.\n"
fi

# ── 3. Targeted Symlinking ────────────────────────────────────────────────────
info "Step 3: Configurations"
if ask_permission "Symlink dotfiles to ~/.config?"; then
    for item in "${TARGETS[@]}"; do
        TARGET_PATH="$HOME/.config/$item"
        SRC_PATH="$INSTALL_LOC/$item"

        if [[ -d "$SRC_PATH" ]]; then
            if [[ -L "$TARGET_PATH" ]] && [[ "$(readlink "$TARGET_PATH")" == "$SRC_PATH" ]]; then
                info "Already linked: $item"
                continue
            fi

            if [[ -e "$TARGET_PATH" ]] || [[ -L "$TARGET_PATH" ]]; then
                mv "$TARGET_PATH" "$(get_backup_dir)/"
            fi

            ln -sf "$SRC_PATH" "$TARGET_PATH"
            find "$SRC_PATH" -type f -name "*.sh" -exec chmod +x {} +
            success "Linked: $item"
        else
            warn "Source directory $SRC_PATH not found. Skipping."
        fi
    done
    echo ""
else
    info "Skipped configurations symlinking.\n"
fi

# ── 4. Wallpapers ─────────────────────────────────────────────────────────────
info "Step 4: Wallpapers"
if ask_permission "Install wallpapers to ~/Pictures & ~/Videos?"; then
    WALLPAPER_STATIC_SRC="$INSTALL_LOC/assets/wallpapers-static"
    WALLPAPER_ANIMATED_SRC="$INSTALL_LOC/assets/wallpapers-animated"
    WALLPAPER_STATIC_DEST="$HOME/Pictures/Wallpapers/meloworld-wallpapers"
    WALLPAPER_ANIMATED_DEST="$HOME/Videos/Wallpapers/meloworld-wallpapers"

    if [[ -d "$WALLPAPER_STATIC_SRC" ]]; then
        mkdir -p "$HOME/Pictures/Wallpapers"
        rm -rf "$WALLPAPER_STATIC_DEST"
        cp -r "$WALLPAPER_STATIC_SRC" "$WALLPAPER_STATIC_DEST"
        success "Static wallpapers installed to $WALLPAPER_STATIC_DEST"
    else
        warn "Static wallpaper source not found at $WALLPAPER_STATIC_SRC"
    fi

    if [[ -d "$WALLPAPER_ANIMATED_SRC" ]]; then
        mkdir -p "$HOME/Videos/Wallpapers"
        rm -rf "$WALLPAPER_ANIMATED_DEST"
        cp -r "$WALLPAPER_ANIMATED_SRC" "$WALLPAPER_ANIMATED_DEST"
        success "Animated wallpapers installed to $WALLPAPER_ANIMATED_DEST"
    else
        warn "Animated wallpaper source not found at $WALLPAPER_ANIMATED_SRC"
    fi

    echo ""
else
    info "Skipped wallpaper installation.\n"
fi

# ── 5. .zshrc Symlink ─────────────────────────────────────────────────────────
info "Step 5: Zsh Configuration"
if ask_permission "Symlink .zshrc?"; then
    ZSHRC_TARGET="$HOME/.zshrc"
    ZSHRC_SRC="$INSTALL_LOC/.zshrc"
    if [[ -f "$ZSHRC_SRC" ]]; then
        if [[ -L "$ZSHRC_TARGET" ]] && [[ "$(readlink "$ZSHRC_TARGET")" == "$ZSHRC_SRC" ]]; then
            info "Already linked: .zshrc\n"
        else
            if [[ -f "$ZSHRC_TARGET" ]] || [[ -L "$ZSHRC_TARGET" ]]; then
                mv "$ZSHRC_TARGET" "$(get_backup_dir)/"
            fi
            ln -sf "$ZSHRC_SRC" "$ZSHRC_TARGET"
            success "Linked: .zshrc\n"
        fi
    else
        warn ".zshrc not found at $ZSHRC_SRC. Skipping.\n"
    fi
else
    info "Skipped .zshrc symlinking.\n"
fi

# ── 6. Keyboard Configuration ─────────────────────────────────────────────────
info "Step 6: Keyboard Configuration"
if ask_permission "Configure keyboard layout for Niri?"; then
    CURRENT_LAYOUT=$(localectl status 2>/dev/null | awk '/X11 Layout/ {print $3}' | head -n 1)
    CURRENT_LAYOUT="${CURRENT_LAYOUT:-us}"

    echo -ne "${PURPLE}==> ${YELLOW}Enter your preferred keyboard layout (e.g., us, tr, de, fr) [default: ${CURRENT_LAYOUT}]: ${RESET}"
    read -r USER_LAYOUT
    USER_LAYOUT="${USER_LAYOUT:-$CURRENT_LAYOUT}"

    INPUT_CONF="$INSTALL_LOC/niri/input.kdl"

    if [[ -f "$INPUT_CONF" ]]; then
        sed -i "s/layout = \".*\"/layout = \"$USER_LAYOUT\"/" "$INPUT_CONF"
        success "Keyboard layout set to '$USER_LAYOUT' in $INPUT_CONF.\n"
    else
        warn "Niri input config not found at $INPUT_CONF. Could not update layout.\n"
    fi
else
    info "Skipped keyboard configuration.\n"
fi

# ── 7. System & SDDM ──────────────────────────────────────────────────────────
info "Step 7: System Setup"

if ask_permission "Enable SDDM (and disable other display managers)?"; then
    sudo systemctl disable gdm lightdm ly 2>/dev/null || true
    sudo systemctl enable sddm
    success "SDDM enabled."
fi

if ask_permission "Install and configure SDDM theme files?"; then
    sudo mkdir -p /usr/share/sddm/themes/
    sudo cp -r "$INSTALL_LOC/meloworld-sddm" /usr/share/sddm/themes/

    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=meloworld-sddm\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
    success "Meloworld SDDM theme installed and configured."
fi

if ask_permission "Apply final preferences & set Zsh as default shell?"; then
    sudo systemctl enable --now bluetooth power-profiles-daemon switcheroo-control

    gsettings set org.gnome.desktop.wm.preferences button-layout ":" 2>/dev/null ||
        warn "gsettings: could not set button-layout (GNOME schema may not be present)."
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null ||
        warn "gsettings: could not set gtk-theme."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null ||
        warn "gsettings: could not set color-scheme."

    if [[ "$SHELL" != */zsh ]]; then
        if command -v zsh >/dev/null 2>&1; then
            sudo chsh -s "$(command -v zsh)" "$USER"
            success "Default shell changed to Zsh."
        else
            warn "Zsh is not installed, cannot change default shell."
        fi
    else
        info "Zsh is already the default shell."
    fi
fi

echo -e "\n${GREEN}Meloworld is ready! Please reboot your system to apply all changes. Also please read the usage tips from the GitHub.${RESET}\n"
