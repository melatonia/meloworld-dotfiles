#!/bin/bash
# 1. Instant capture to avoid "behind" frames
grim /tmp/qs-master.png

# 2. Open the Quickshell UI
quickshell -c ~/.config/quickshell/screenshot/
