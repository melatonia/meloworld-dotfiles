#!/usr/bin/env bash

# ── Colors (Matching Jovial Palette) ──────────────────────────────────────────
PURPLE='\033[1;35m'
GREEN='\033[1;32m'
YELLOW='\033[1;228m'
BLUE='\033[1;157m'
RESET='\033[0m'

# ── Paths & Variables ─────────────────────────────────────────────────────────
REPO_NAME="meloworld-dotfiles"
INSTALL_LOC="$HOME/.config/$REPO_NAME"
BACKUP_DIR="$HOME/.config_backup/$(date +%Y%m%d_%H%M%S)"
TARGETS=("quickshell" "mango" "ghostty" "hypr" "rofi" "zed")

# ── Helper: Ask Permission ────────────────────────────────────────────────────
ask_permission() {
    echo -ne "${YELLOW}$1 [y/N]: ${RESET}"
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
echo -e "${BLUE}Installing Meloworld rice...${RESET}\n"

# ── 1. Repository Migration ───────────────────────────────────────────────────
echo -e "${PURPLE}Step 1: Permanent Placement${RESET}"
if ask_permission "Move dotfiles to $INSTALL_LOC?"; then
    CURRENT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    if [ "$CURRENT_DIR" != "$INSTALL_LOC" ]; then
        mkdir -p "$HOME/.config"
        [ -d "$INSTALL_LOC" ] && mv "$INSTALL_LOC" "${BACKUP_DIR}_repo_old"
        cp -r "$CURRENT_DIR" "$INSTALL_LOC"
        echo -e "${GREEN}Migration successful.${RESET}\n"
    else
        echo -e "${BLUE}Repository already in place.${RESET}\n"
    fi
fi

# ── 2. Dependencies ───────────────────────────────────────────────────────────
echo -e "${PURPLE}Step 2: Dependencies${RESET}"
if ask_permission "Install required packages?"; then
    [ -x "$(command -v paru)" ] && PKGER="paru" || PKGER="yay"
    $PKGER -S --needed --noconfirm mangowm quickshell pipewire pipewire-pulse \
    wireplumber bluez bluez-utils brightnessctl ghostty power-profiles-daemon \
    polkit-gnome ttf-jetbrains-mono-nerd rofi rofi-emoji grim slurp awww \
    bibata-cursor-theme-bin papirus-icon-theme zed zsh zsh-autosuggestions \
    zsh-syntax-highlighting eza sddm
fi

# ── 3. Targeted Symlinking ────────────────────────────────────────────────────
echo -e "${PURPLE}Step 3: Configurations${RESET}"
if ask_permission "Symlink dotfiles to ~/.config?"; then
    for item in "${TARGETS[@]}"; do
        if [ -d "$INSTALL_LOC/$item" ]; then
            if [ -e "$HOME/.config/$item" ]; then
                mkdir -p "$BACKUP_DIR"
                mv "$HOME/.config/$item" "$BACKUP_DIR/"
            fi
            ln -sf "$INSTALL_LOC/$item" "$HOME/.config/$item"
            find "$HOME/.config/$item" -type f -name "*.sh" -exec chmod +x {} +
            echo -e "${GREEN}Linked:${RESET} $item"
        fi
    done

    if [ -f "$INSTALL_LOC/.zshrc" ]; then
        [ -f "$HOME/.zshrc" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.zshrc" "$BACKUP_DIR/"
        ln -sf "$INSTALL_LOC/.zshrc" "$HOME/.zshrc"[cite: 1]
        echo -e "${GREEN}Linked:${RESET} .zshrc[cite: 1]"
    fi
fi

# ── 4. System & SDDM ──────────────────────────────────────────────────────────
echo -e "${PURPLE}Step 4: System Setup${RESET}"

if ask_permission "Enable SDDM (and disable others)?"; then
    sudo systemctl disable gdm lightdm ly 2>/dev/null
    sudo systemctl enable sddm
fi

if ask_permission "Install SDDM theme files?"; then
    sudo mkdir -p /usr/share/sddm/themes/
    sudo cp -r "$INSTALL_LOC/meloworld-sddm" /usr/share/sddm/themes/
    echo -e "\n${YELLOW}MANUAL STEP:${RESET} Add\n${PURPLE}[Theme]\nCurrent=meloworld-sddm${RESET}\nto ${BLUE}/etc/sddm.conf.d/theme.conf${RESET}\n"
fi

if ask_permission "Apply final preferences & set Zsh?"; then
    sudo systemctl enable --now bluetooth power-profiles-daemon
    gsettings set org.gnome.desktop.wm.preferences button-layout ":"
    # Switch shell to Zsh to activate history and plugin settings
    [[ "$SHELL" != */zsh ]] && chsh -s "$(which zsh)"[cite: 1]
fi

echo -e "${GREEN}Meloworld is ready! Please reboot.${RESET}"
