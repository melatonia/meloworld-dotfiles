#!/bin/bash
mkdir -p ~/Pictures/Screenshots
FILE=~/Pictures/Screenshots/Screenshot\ From\ $(date +%Y-%m-%d\ %H-%M-%S).png
grim -g "$(slurp)" "$FILE" && wl-copy < "$FILE" && notify-send "Screenshot Captured" "Saved to Pictures/Screenshots"
pw-play ~/.config/mango/screenshot.mp3
