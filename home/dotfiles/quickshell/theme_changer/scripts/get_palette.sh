#!/usr/bin/env bash
WALLPAPER="$1"
WAL_CACHE="$HOME/.cache/wallust"

rm -rf "$WAL_CACHE"
wallust run "$WALLPAPER" -s -q > /dev/null 2>&1

jq -c '.' "$WAL_CACHE/colors.json"
