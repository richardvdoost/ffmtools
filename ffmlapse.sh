#!/bin/bash

NOW=$(date +"%y-%m-%d_%H:%M:%S")
FRAMES_DIR="/tmp/screenlapse-$NOW"

# Capture screen every 2 seconds
mkdir -p "$FRAMES_DIR"
FRAME=0
echo "Capturing screen, hit q to stop"
while :; do
    screencapture -Cx "$FRAMES_DIR/frame-$(printf '%06d' $FRAME).png"
    FRAME=$((FRAME + 1))

    read -r -t 2 -n 1 input
    if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
        echo
        break
    fi
done
echo

set -e

# Create a timelapse of the captured images
echo "Creating timelapse"
ffmpeg \
    -v quiet \
    -stats \
    -f image2 \
    -r 30 \
    -i "$FRAMES_DIR/frame-%06d.png" \
    -r 30 \
    -pix_fmt yuv420p \
    -y "screenlapse-$NOW.mp4"

# Delete all captured images
rm -r "$FRAMES_DIR"
