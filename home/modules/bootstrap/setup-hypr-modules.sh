#!/usr/bin/env bash

MODULES_DIR="$HOME/.config/hypr/modules"
TEMPLATE_DIR="${TEMPLATE_DIR:?TEMPLATE_DIR not set}"

mkdir -p "$MODULES_DIR"

create_if_missing() {
    local target="$1"
    local template="$2"

    if [ ! -f "$target" ]; then
        echo "Module missing, creating: $target"
        cp "$template" "$target"
        chmod 644 "$target"
    else
        echo "Module $target exists, skipping"
    fi
}

create_if_missing \
    "$MODULES_DIR/custom-keybinds.lua" \
    "$TEMPLATE_DIR/custom-keybinds.lua"

create_if_missing \
    "$MODULES_DIR/device-settings.lua" \
    "$TEMPLATE_DIR/device-settings.lua"

create_if_missing \
    "$MODULES_DIR/monitors.lua" \
    "$TEMPLATE_DIR/monitors.lua"
