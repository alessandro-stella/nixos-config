#!/usr/bin/env bash

declare -A links=(
    ["$HOME/.config/kitty/colors-kitty.conf"]="kitty.conf"
    ["$HOME/.config/oh-my-posh/themes/current_theme.omp.json"]="oh-my-posh.omp.json"
    ["$HOME/.config/rofi/colors.rasi"]="rofi.rasi"
    ["$HOME/.config/swaync/style.css"]="swaync.css"
    ["$HOME/.config/waybar/style.css"]="waybar.css"
    ["$HOME/.config/wlogout/style.css"]="wlogout.css"
    ["$HOME/.config/hypr/modules/dynamic-border.lua"]="dynamic-border.lua"
    ["$HOME/.config/foot/colors-foot.ini"]="foot.ini"
)

for target in "${!links[@]}"; do
    mkdir -p "$(dirname "$target")"
    ln -sfn "$HOME/.config/themes/current_theme/${links[$target]}" "$target"
done
