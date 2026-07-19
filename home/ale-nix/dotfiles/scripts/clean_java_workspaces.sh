#!/bin/bash

WORKSPACE="$HOME/.workspaces-java"

# Delete all subfolders older than 3 months
find "$WORKSPACE" -mindepth 1 -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \;

# Create directory if not existing
mkdir -p "$WORKSPACE"
