#!/usr/bin/env bash

WALLPAPER="$1"
WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"

# Genera solo la palette (e aggiorna la cache di wal) SENZA toccare il sistema:
#   -n  non imposta il wallpaper
#   -s  non cambia i colori dei terminali aperti
#   -t  non cambia i colori delle TTY
#   -e  non ricarica gtk/xrdb/i3/sway/polybar ecc.
#   -q  silenzioso
wal -i "$WALLPAPER" -n -s -t -e -q > /dev/null 2>&1

jq -c '[.colors[]]' "$WAL_CACHE/colors.json"
