#!/bin/bash
# Restores the last wallpaper on login.
# Reads ~/.cache/meloworld/last-wallpaper which is written by the QML wallpaper picker.
# Format: "video:/path/to/file" or "image:/path/to/file"

STATE="$HOME/.cache/meloworld/last-wallpaper"

if [ ! -f "$STATE" ]; then
    # No saved state yet — fall back to awww-daemon with no wallpaper set
    awww-daemon &
    exit 0
fi

TYPE=$(cut -d: -f1 "$STATE")
WALL=$(cut -d: -f2- "$STATE")

if [ ! -f "$WALL" ]; then
    # Saved wallpaper file no longer exists — fall back gracefully
    awww-daemon &
    exit 0
fi

if [ "$TYPE" = "video" ]; then
    mpvpaper -f -p -o '--loop-file=inf --no-audio --hwdec=auto' ALL "$WALL"
else
    awww-daemon &
    while ! awww query &>/dev/null; do sleep 0.05; done
    awww img "$WALL" --transition-type none
fi
