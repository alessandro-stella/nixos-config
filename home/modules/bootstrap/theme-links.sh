#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_THEMES="$SCRIPT_DIR/../../dotfiles/themes"
THEME_DIR="$HOME/.config/themes"
CURRENT_THEME="$THEME_DIR/current_theme"
APPLY_SCRIPT="$HOME/.config/quickshell/theme_changer/scripts/apply_theme.sh"
CREATED_NEW_THEME=false

if [ ! -d "$CURRENT_THEME" ]; then
    mkdir -p "$THEME_DIR"
    
    FIRST_THEME=$(find "$REPO_THEMES" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    
    if [ -n "$FIRST_THEME" ]; then
        cp -r "$FIRST_THEME" "$CURRENT_THEME"
        chmod -R +w "$CURRENT_THEME"
        CREATED_NEW_THEME=true
        echo "Initializing current_theme using: $(basename "$FIRST_THEME")"
    else
        echo "No theme found in $REPO_THEMES. Can't initialize current_theme."
        exit 1
    fi
fi

declare -A links=(
  ["$HOME/.config/oh-my-posh/current_theme.omp.json"]="current_theme.omp.json"
  ["$HOME/.config/swaync/style.css"]="swaync.css"
  ["$HOME/.config/hypr/modules/dynamic-border.lua"]="dynamic-border.lua"
  ["$HOME/.config/foot/colors-foot.ini"]="colors-foot.ini"
)

for target in "${!links[@]}"; do
  mkdir -p "$(dirname "$target")"
  ln -sfn "$CURRENT_THEME/${links[$target]}" "$target"
done

if [ "$CREATED_NEW_THEME" = true ]; then
    DEFAULT_THEME_NAME=$(basename "$FIRST_THEME")
    echo "Applying default theme configuration for: $DEFAULT_THEME_NAME"
    
    if [ -f "$APPLY_SCRIPT" ]; then
        "$APPLY_SCRIPT" "$DEFAULT_THEME_NAME"
    else
        echo "Warning: Apply script not found at $APPLY_SCRIPT"
    fi
fi
