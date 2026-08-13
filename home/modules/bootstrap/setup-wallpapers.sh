#!/usr/bin/env bash

PICS_DIR="$HOME/Pictures"
WP_DIR="$PICS_DIR/wallpapers"
REPO_URL="https://github.com/alessandro-stella/linux-wallpapers.git"

mkdir -p "$PICS_DIR"

if [ ! -d "$WP_DIR/.git" ]; then
    echo "Downloading wallpapers..."

    rm -rf "$WP_DIR"
    git clone "$REPO_URL" "$WP_DIR"

    "$HOME/.config/scripts/theme_changer/generate_thumbnails.sh"
else
    echo "Wallpaper folder exists, checking for updates..."

    if git -C "$WP_DIR" pull --ff-only; then
        "$HOME/.config/scripts/theme_changer/generate_thumbnails.sh"
    else
        echo "Failed to update wallpapers."
    fi
fi
