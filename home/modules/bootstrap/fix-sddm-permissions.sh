#!/usr/bin/env bash

set -euo pipefail

USERNAME="$1"
THEME_PATH="/home/${USERNAME}/.config/themes/current_theme"

chmod +x "/home/${USERNAME}"
chmod +x "/home/${USERNAME}/.config"
chmod +x "/home/${USERNAME}/.config/themes"

if [ -e "${THEME_PATH}" ]; then
    chmod +r "${THEME_PATH}"
fi

if [ -f "${THEME_PATH}/wallpaper.png" ]; then
    chmod +r "${THEME_PATH}/wallpaper.png"
fi
