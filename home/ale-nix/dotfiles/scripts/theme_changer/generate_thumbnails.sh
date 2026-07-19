#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
THUMB_DIR="$WALLPAPER_DIR/thumbnails"
THUMB_SIZE="320x180"
QUALITY=80

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: $WALLPAPER_DIR directory not found."
    exit 1
fi

mkdir -p "$THUMB_DIR"

# Trova i wallpaper
mapfile -t WALLPAPERS < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \)
)

# Salva i nomi base dei wallpaper
declare -A WALL_NAMES
for FILE in "${WALLPAPERS[@]}"; do
    NAME="$(basename "$FILE")"
    WALL_NAMES["${NAME%.*}"]=1
done

# Pulisce le thumbnail orfane
mapfile -t THUMBS < <(find "$THUMB_DIR" -maxdepth 1 -type f -iname "*.png")
for THUMB in "${THUMBS[@]}"; do
    NAME="$(basename "$THUMB")"
    BASE="${NAME%.png}"
    if [ -z "${WALL_NAMES[$BASE]}" ]; then
        rm -f "$THUMB"
    fi
done

# Trova le thumbnail mancanti
MISSING=()
for FILE in "${WALLPAPERS[@]}"; do
    NAME="$(basename "$FILE")"
    BASE="${NAME%.*}"
    THUMB_FILE="$THUMB_DIR/$BASE.png"
    if [ ! -f "$THUMB_FILE" ]; then
        MISSING+=("$FILE")
    fi
done

TOTAL_MISSING=${#MISSING[@]}

if [ "$TOTAL_MISSING" -eq 0 ]; then 
    echo "No thumbnail to create"
    exit 0
fi

echo "Found $TOTAL_MISSING thumbnails to create:"
for FILE in "${MISSING[@]}"; do
    echo " - $(basename "$FILE")"
done
echo "Creating thumbnails..."

for FILE in "${MISSING[@]}"; do
    mogrify -path "$THUMB_DIR" \
            -thumbnail "$THUMB_SIZE^" \
            -gravity center \
            -extent "$THUMB_SIZE" \
            -quality "$QUALITY" \
            -format png \
            "$FILE"
done

echo "Operation completed!"
