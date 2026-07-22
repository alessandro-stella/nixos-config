#!/usr/bin/env bash

THEME_DIR="$2"
WAL_COLORS_JSON="$THEME_DIR/colors-kitty.conf"
TEMPLATE_CSS="$HOME/.config/waybar/template.css"
OUTPUT_CSS="$THEME_DIR/waybar.css"
LOGO_HEX=${1:-"#89b4fa"}
ALPHA=0.8

BG_HEX=$(grep -m1 'background' "$WAL_COLORS_JSON" | grep -oE '#[0-9a-fA-F]{6}') || exit 1

convertToRgba() {
    local hex="${1#\#}"; local alpha="${2:-1.0}"
    local r=$((16#${hex:0:2})); local g=$((16#${hex:2:2})); local b=$((16#${hex:4:2}))
    LC_NUMERIC=C printf "rgba(%d, %d, %d, %.2f)" "$r" "$g" "$b" "$alpha"
}

sed -e "s/__BACKGROUND_COLOR__/$(convertToRgba "$BG_HEX" "$ALPHA")/g" \
    -e "s/__LOGO_COLOR__/$(convertToRgba "$LOGO_HEX" 1.0)/g" \
    "$TEMPLATE_CSS" > "$OUTPUT_CSS"
