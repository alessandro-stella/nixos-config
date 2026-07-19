#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

wallpaper_dir="$HOME/Pictures/wallpapers/thumbnails"
cache_dir="$HOME/.cache/wallpaper_rofi"
gif_cache_dir="$HOME/.cache/gif_preview"
video_cache_dir="$HOME/.cache/video_preview"
cache_list="$cache_dir/wallpaper_list.cache"
cache_hash="$cache_dir/dir_hash.txt"
theme_path="$HOME/.config/rofi/theme_changer.rasi"

mkdir -p "$cache_dir" "$gif_cache_dir" "$video_cache_dir"

hash_dir_state() {
    find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -printf "%T@ %p\n" | sort | sha256sum | cut -d ' ' -f1
}

generate_cache() {
    local hash
    hash=$(hash_dir_state)
    > "$cache_list"
    find -L "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) | sort -V > "$cache_list"
    echo "$hash" > "$cache_hash"
}

check_cache() {
    [[ ! -f "$cache_list" ]] && return 1
    [[ ! -f "$cache_hash" ]] && return 1
    local old_hash new_hash
    old_hash=$(cat "$cache_hash")
    new_hash=$(hash_dir_state)
    [[ "$old_hash" != "$new_hash" ]] && return 1
    return 0
}

generate_menu() {
    mapfile -t PICS < "$cache_list"
    for pic_path in "${PICS[@]}"; do
        pic_name=$(basename "$pic_path")
        display_name="${pic_name%.*}"
        printf "%s\x00icon\x1f%s\n" "$display_name" "$pic_path"
    done
}

main() {
    "$(dirname "$0")/generate_thumbnails.sh" || { echo "Error during thumbnails generation" >&2; exit 1; }

    if [[ "${1:-}" == "--refresh" ]]; then
        generate_cache
    elif ! check_cache; then
        generate_cache
    fi

    choice=$(generate_menu | rofi -dmenu -i -theme "$theme_path" -markup-rows -p "Choose wallpaper:")

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    mapfile -t PICS < "$cache_list"
    selected_file=""
    for pic_path in "${PICS[@]}"; do
        pic_name=$(basename "$pic_path")
        display_name="${pic_name%.*}"
        if [[ "$choice" == "$pic_name" || "$choice" == "$display_name" ]]; then
            selected_file="$pic_path"
            break
        fi
    done

    if [[ -f "$selected_file" ]]; then
        original_file="${selected_file/\/thumbnails/}"
        theme_name=$(basename "${original_file%.*}")
        theme_dir="$HOME/.config/themes/$theme_name"
        mkdir -p "$theme_dir"
        
        "$(dirname "$0")/wallpaper_changer.sh" "$original_file" "$theme_dir"
    else
        notify-send -u low 'Changing theme...' "Wallpaper: $(basename "$original_file")"
    fi
}

main "$@"
