#!/usr/bin/env bash

case "$1" in
    d) # Delete mode
        cliphist list | rofi -dmenu -p "Delete Clipboard" | cliphist delete
        ;;
    w) # Wipe mode
        cliphist wipe
        ;;
    *) # Standard Picker
        cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
        ;;
esac
