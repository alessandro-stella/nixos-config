# NixOS Hyprland Flake Configuration

This repository contains my personal system and user configurations managed via Nix Flakes, including an automated theme and wallpaper switching pipeline optimized to preserve symbolic links.

## Quick Start

Run the following commands in sequence to clone the repository and deploy the configuration using Nix Flakes.

```bash
# 1. Enter a temporary shell with Git (if not installed globally)
nix shell nixpkgs#git

# 2. Clone the repository and enter the directory
git clone [https://github.com/YOUR_USERNAME/YOUR_REPO.git](https://github.com/YOUR_USERNAME/YOUR_REPO.git) ~/dotfiles
cd ~/dotfiles

# 3. Build and switch to the system configuration (NixOS)
# Replace 'YOUR_HOSTNAME' with the specific output name in your flake.nix
sudo nixos-rebuild switch --flake .#YOUR_HOSTNAME

# 4. Build and switch to the user configuration (Home Manager)
# Replace 'YOUR_USERNAME' with the specific configuration target in your flake
home-manager switch --flake .#YOUR_USERNAME
