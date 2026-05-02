#!/bin/bash
udevadm monitor --udev --subsystem-match=usb | while read -r line; do
    if echo "$line" | grep -qP "^\S+\s+\S+\s+bind\s+/devices/.*usb\d+/[^/:]+\s+\(usb\)$"; then
        pw-play ~/.config/mango/assets/sounds/usb-connect.flac
    elif echo "$line" | grep -qP "^\S+\s+\S+\s+unbind\s+/devices/.*usb\d+/[^/:]+\s+\(usb\)$"; then
        pw-play ~/.config/mango/assets/sounds/usb-remove.flac
    fi
done
