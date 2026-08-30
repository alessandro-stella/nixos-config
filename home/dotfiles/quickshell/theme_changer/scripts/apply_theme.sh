#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

THEME_NAME="$1"

if [[ -z "$THEME_NAME" ]]; then
    log_error "Usage: apply_theme.sh <theme_name>"
    exit 1
fi

THEME_BASE_DIR="$HOME/.config/themes"
THEME_DIR="$THEME_BASE_DIR/$THEME_NAME"
CURRENT_THEME_DIR="$THEME_BASE_DIR/current_theme"

if [[ ! -d "$THEME_DIR" ]]; then
    log_error "Theme folder not found: $THEME_DIR"
    exit 1
fi

log_info "Applying theme '$THEME_NAME'..."
mkdir -p "$CURRENT_THEME_DIR"

update_file() {
  local src="$1"
  local dest="$2"
  
  if [ -f "$src" ]; then
    if [ -L "$dest" ] || [ "$src" -ef "$dest" ]; then
      rm -f "$dest"
      cp "$src" "$dest"
    else
      cat "$src" > "$dest"
    fi
  fi
}

log_info "Updating theme files..."
update_file "$THEME_DIR/wallpaper.png" "$CURRENT_THEME_DIR/wallpaper.png"
update_file "$THEME_DIR/colors-foot.ini" "$CURRENT_THEME_DIR/colors-foot.ini"
update_file "$THEME_DIR/swaync.css" "$CURRENT_THEME_DIR/swaync.css"
update_file "$THEME_DIR/theme.omp.json" "$CURRENT_THEME_DIR/current_theme.omp.json"
update_file "$THEME_DIR/Accents.qml" "$CURRENT_THEME_DIR/Accents.qml"
update_file "$THEME_DIR/dynamic-border.lua" "$CURRENT_THEME_DIR/dynamic-border.lua"
update_file "$THEME_DIR/colors.json" "$CURRENT_THEME_DIR/colors.json"

echo "$THEME_NAME" > "$CURRENT_THEME_DIR/name"
log_success "Current theme name saved in $CURRENT_THEME_DIR/name"

log_info "Changing wallpaper..."
if command -v awww &>/dev/null; then
    if ! awww query &>/dev/null; then
        awww-daemon &
        sleep 0.5
    fi

    if command -v bc &>/dev/null; then
        RAND_X=$(echo "scale=2; $((RANDOM % 101)) / 100" | bc)
        RAND_Y=$(echo "scale=2; $((RANDOM % 101)) / 100" | bc)
    else
        RAND_X="0.5"
        RAND_Y="0.5"
    fi

    awww img "$THEME_DIR/wallpaper.png" \
        --transition-type grow \
        --transition-pos "$RAND_X,$RAND_Y" \
        --transition-step 90 \
        --transition-fps 60 \
        --transition-duration 1.5
else
    log_error "Command 'awww' not found."
fi

log_success "Theme applied successfully!"

if command -v hyprctl &>/dev/null; then
    log_info "Reloading Hyprland configuration..."
    hyprctl reload 2>/dev/null || log_error "Couldn't reload Hyprland configuration"
fi

log_info "Reloading quickshell..."
    
if command -v quickshell &>/dev/null; then
    ( sleep 0.5; pkill quickshell; sleep 0.5; quickshell ) >/dev/null 2>&1 &
    disown
fi

log_info "Reloading swaync..."
    
if command -v swaync-client &>/dev/null; then
  swaync-client -rs
fi
