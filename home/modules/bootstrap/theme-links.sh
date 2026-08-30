#!/usr/bin/env bash

declare -A links=(
  ["$HOME/.config/oh-my-posh/themes/current_theme.omp.json"]="current_theme.omp.json"
  ["$HOME/.config/swaync/style.css"]="swaync.css"
  ["$HOME/.config/hypr/modules/dynamic-border.lua"]="dynamic-border.lua"
  ["$HOME/.config/foot/colors-foot.ini"]="colors-foot.ini"
)

for target in "${!links[@]}"; do
  mkdir -p "$(dirname "$target")"
  ln -sfn "$HOME/.config/themes/current_theme/${links[$target]}" "$target"
done
