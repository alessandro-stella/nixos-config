#!/usr/bin/env bash

set -euo pipefail

SELECTED_IMAGE="$1"
THEME_DIR="$2"
CURRENT_THEME_DIR="$HOME/.config/themes/current_theme"
BLUR_LEVEL="0x12"

REQUIRED_FILES=(
    "blurred_wallpaper.png"
    "wlogout_style.css"
    "dynamic-border.lua"
    "waybar.css"
    "swaync.css"
    "current_theme.omp.json"
    "colors-kitty.conf"
    "colors.json"
    "colors-rofi.rasi"

    "colors-foot.ini"
)

mkdir -p "$CURRENT_THEME_DIR" "$THEME_DIR"

is_theme_complete() {
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$THEME_DIR/$file" ]; then
            echo "$file not found"
            return 1
        fi
    done
    return 0
}

if is_theme_complete; then
    echo "Theme found, copying existing files..."
else 
    notify-send -i "$SELECTED_IMAGE" -u low 'Building theme...' "Wallpaper: $(basename "$SELECTED_IMAGE")"
    echo "Incomplete or missing theme, building needed files..."
    
    for cmd in magick awww bc; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: '$cmd' is not installed."
            exit 1
        fi
    done

    if ! awww query &>/dev/null; then
        awww-daemon &
        sleep 0.5
    fi

    PALETTE_SCRIPT="$(dirname "$0")/palette_changer.sh"
    "$PALETTE_SCRIPT" "$SELECTED_IMAGE" "$THEME_DIR"

    echo "Genating blurred wallpaper..."
    magick "$SELECTED_IMAGE" -resize 1920x1080^ -gravity center -extent 1920x1080 -blur "$BLUR_LEVEL" "$THEME_DIR/blurred_wallpaper.png"
fi

update_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    cat "$src" > "$dest"
  fi
}

echo "Applying theme files..."
update_file "$SELECTED_IMAGE" "$CURRENT_THEME_DIR/wallpaper.png"
update_file "$THEME_DIR/blurred_wallpaper.png" "$CURRENT_THEME_DIR/blurred_wallpaper.png" 
update_file "$THEME_DIR/wlogout_style.css" "$CURRENT_THEME_DIR/wlogout.css"
update_file "$THEME_DIR/dynamic-border.lua" "$CURRENT_THEME_DIR/dynamic-border.lua" 
update_file "$THEME_DIR/waybar.css" "$CURRENT_THEME_DIR/waybar.css"
update_file "$THEME_DIR/swaync.css" "$CURRENT_THEME_DIR/swaync.css"
update_file "$THEME_DIR/current_theme.omp.json" "$CURRENT_THEME_DIR/oh-my-posh.omp.json"
update_file "$THEME_DIR/colors-rofi.rasi" "$CURRENT_THEME_DIR/rofi.rasi" 
update_file "$THEME_DIR/colors-kitty.conf" "$CURRENT_THEME_DIR/kitty.conf"
update_file "$THEME_DIR/colors-foot.ini" "$CURRENT_THEME_DIR/foot.ini"

RAND_X=$(echo "scale=2; $((RANDOM % 101)) / 100" | bc)
RAND_Y=$(echo "scale=2; $((RANDOM % 101)) / 100" | bc)

awww img "$SELECTED_IMAGE" \
    --transition-type grow \
    --transition-pos "$RAND_X,$RAND_Y" \
    --transition-step 90 \
    --transition-fps 60 \
    --transition-duration 1.5

hyprctl reload
pkill -f waybar || true
sleep 0.1
waybar &
swaync-client -R && swaync-client -rs

echo "Wallpaper update process completed!"
