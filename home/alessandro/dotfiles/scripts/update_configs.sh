#!/usr/bin/env bash

REPOS=(
  "$HOME/nixos-config"
  "$HOME/.config/nvim"
)

for REPO in "${REPOS[@]}"; do
  if [ -d "$REPO/.git" ]; then
    cd "$REPO" || continue

    git fetch -q 2>/dev/null

    BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null)

    REPO_NAME=$(basename "$REPO")

    if [ -n "$BEHIND" ] && [ "$BEHIND" -gt 0 ]; then
      notify-send -u critical "Updates for $REPO_NAME" "There are $BEHIND new commits to download"
    fi
  else
    notify-send "[$REPO] is not a valid git repository"
  fi
done
