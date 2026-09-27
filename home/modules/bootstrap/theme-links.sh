#!/usr/bin/env bash

REPO_ROOT="${1:-$HOME/nixos-config}"
REPO_THEMES="$REPO_ROOT/home/dotfiles/themes"
THEME_DIR="$HOME/.config/themes"
CURRENT_THEME="$THEME_DIR/current_theme"

if [ ! -d "$CURRENT_THEME" ]; then
    mkdir -p "$THEME_DIR"
    
    FIRST_THEME=$(find "$REPO_THEMES" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    
    if [ -n "$FIRST_THEME" ]; then
        cp -r "$FIRST_THEME" "$CURRENT_THEME"
        echo "Initializing current_theme using: $(basename "$FIRST_THEME")"
    else
        echo "No theme found in $REPO_THEMES. Can't initialize current_theme."
        exit 1
    fi
fi

declare -A links=(
  ["$HOME/.config/oh-my-posh/themes/current_theme.omp.json"]="current_theme.omp.json"
  ["$HOME/.config/swaync/style.css"]="swaync.css"
  ["$HOME/.config/hypr/modules/dynamic-border.lua"]="dynamic-border.lua"
  ["$HOME/.config/foot/colors-foot.ini"]="colors-foot.ini"
)

for target in "${!links[@]}"; do
  mkdir -p "$(dirname "$target")"
  ln -sfn "$CURRENT_THEME/${links[$target]}" "$target"
done
