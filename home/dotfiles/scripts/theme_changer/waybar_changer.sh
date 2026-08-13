#!/usr/bin/env bash

THEME_DIR="$2"
WAL_COLORS_JSON="$THEME_DIR/colors-foot.ini"
TEMPLATE_CSS="$HOME/.config/waybar/template.css"
OUTPUT_CSS="$THEME_DIR/waybar.css"
LOGO_HEX=${1:-"#89b4fa"}
ALPHA=0.8

BG_HEX=$(grep -A 30 '^\[colors-dark\]' "$FOOT_CONFIG" | grep '^background=' | grep -oE '[0-9A-Fa-f]{6}' | head -1)
BG_HEX="#$BG_HEX" || exit 1

convertToRgba() {
    local hex="${1#\#}"; local alpha="${2:-1.0}"
    local r=$((16#${hex:0:2})); local g=$((16#${hex:2:2})); local b=$((16#${hex:4:2}))
    LC_NUMERIC=C printf "rgba(%d, %d, %d, %.2f)" "$r" "$g" "$b" "$alpha"
}

sed -e "s/__BACKGROUND_COLOR__/$(convertToRgba "$BG_HEX" "$ALPHA")/g" \
    -e "s/__LOGO_COLOR__/$(convertToRgba "$LOGO_HEX" 1.0)/g" \
    "$TEMPLATE_CSS" > "$OUTPUT_CSS"
