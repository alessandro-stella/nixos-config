#!/usr/bin/env bash

NVIM_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/alessandro-stella/OrionVim.git"

if [ ! -d "$NVIM_DIR/.git" ]; then
    echo "Cloning OrionVim..."
    rm -rf "$NVIM_DIR"
    git clone "$REPO_URL" "$NVIM_DIR"
else
    echo "OrionVim already installed, checking updates..."
    git -C "$NVIM_DIR" pull --ff-only || \
        echo "Failed to update Neovim (offline or local changes detected)."
fi
