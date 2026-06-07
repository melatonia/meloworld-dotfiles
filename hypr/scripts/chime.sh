#!/bin/bash
while ! pw-cli info 0 &>/dev/null; do
    sleep 0.3
done

sleep 0.3
pw-play ~/.config/hypr/assets/sounds/chime.flac
