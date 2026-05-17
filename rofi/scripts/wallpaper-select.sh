#!/usr/bin/env bash
# ── meloworld-wallpaper — rofi wallpaper selector ────────────────────────────
# Place at:  ~/.config/rofi/scripts/wallpaper-select.sh
# Make exec: chmod +x ~/.config/rofi/scripts/wallpaper-select.sh
#
# Backends supported (auto-detected, in order of preference):
#   swww    — Wayland, smooth animated transitions  (recommended)
#   hyprpaper — Wayland, Hyprland's native daemon
#   swaybg  — Wayland, simple one-shot setter
#   feh     — X11
#   nitrogen — X11
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/themes/meloworld-wallpaper.rasi"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/meloworld"
LAST_WALL="$CACHE_DIR/last-wallpaper"

# awww transition settings (ignored for other backends)
AWWW_TRANSITION="${AWWW_TRANSITION:-fade}"
AWWW_DURATION="${AWWW_DURATION:-0.8}"
AWWW_FPS="${AWWW_FPS:-60}"

# ── Helpers ───────────────────────────────────────────────────────────────────
die() { notify-send -u critical "meloworld-wallpaper" "$*"; exit 1; }
info() { notify-send -u low "meloworld-wallpaper" "$*"; }

mkdir -p "$CACHE_DIR"

# ── Backend detection ─────────────────────────────────────────────────────────
detect_backend() {
    if command -v awww &>/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        # Ensure awww daemon is running
        awww query &>/dev/null || awww init
        echo "awww"
    elif command -v hyprpaper &>/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "hyprpaper"
    elif command -v swaybg &>/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "swaybg"
    elif command -v feh &>/dev/null; then
        echo "feh"
    elif command -v nitrogen &>/dev/null; then
        echo "nitrogen"
    else
        die "No wallpaper backend found.\nInstall swww (Wayland) or feh (X11)."
    fi
}

# ── Set wallpaper ─────────────────────────────────────────────────────────────
set_wallpaper() {
    local path="$1"
    case "$BACKEND" in
        awww)
            awww img "$path" \
                --transition-type  "$AWWW_TRANSITION" \
                --transition-duration "$AWWW_DURATION" \
                --transition-fps   "$AWWW_FPS"
            ;;
        hyprpaper)
            hyprctl hyprpaper preload "$path"
            hyprctl hyprpaper wallpaper ",$path"
            ;;
        swaybg)
            pkill swaybg 2>/dev/null || true
            swaybg -m fill -i "$path" &
            ;;
        feh)
            feh --bg-scale "$path"
            ;;
        nitrogen)
            nitrogen --set-scaled "$path"
            ;;
    esac
}

# ── Collect wallpapers ────────────────────────────────────────────────────────
[ -d "$WALLPAPER_DIR" ] || die "Wallpaper directory not found:\n$WALLPAPER_DIR"

mapfile -t files < <(
    find "$WALLPAPER_DIR" \
        \( -iname "*.jpg"  \
        -o -iname "*.jpeg" \
        -o -iname "*.png"  \
        -o -iname "*.webp" \
        -o -iname "*.gif"  \
        -o -iname "*.jxl"  \) \
        -type f | sort
)

[ "${#files[@]}" -gt 0 ] || die "No wallpapers found in:\n$WALLPAPER_DIR"

# ── Build rofi input list ─────────────────────────────────────────────────────
# Format:  display-name \0 icon \x1f /full/path/to/image
# rofi -format i returns the 0-based index of the chosen entry.
build_input() {
    for f in "${files[@]}"; do
        local base="${f##*/}"            # keep extension so png/jpg are distinct
        printf '%s\0icon\x1f%s\n' "${base%.*}" "$f"
    done
}

# ── Run rofi ──────────────────────────────────────────────────────────────────
BACKEND="$(detect_backend)"

selected_idx=$(
    build_input | rofi \
        -dmenu \
        -i \
        -p "󰸉 Wallpaper" \
        -theme "$THEME" \
        -show-icons \
        -format i \
        -no-custom \
        -hover-select \
        -selected-row 0
) || true   # rofi exits 1 on cancel — don't abort the script

[ -z "$selected_idx" ] && exit 0        # user pressed Escape

# ── Apply ─────────────────────────────────────────────────────────────────────
selected_path="${files[$selected_idx]}"
[ -f "$selected_path" ] || die "Resolved path does not exist:\n$selected_path"

set_wallpaper "$selected_path"

# Persist selection for session restore
echo "$selected_path" > "$LAST_WALL"

exit 0
