# NixOS Hyprland Flake Configuration

This repository contains my personal system and user configurations managed via Nix Flakes, including an automated theme and wallpaper switching pipeline optimized to preserve symbolic links.

## Quick Start

Execute these separate steps to clone the repository and deploy the configuration using Nix Flakes.

### 1. Enter a Nix Shell with Git
If you are on a fresh installation and do not have Git installed globally, run this to drop into a temporary shell:

```bash
nix shell nixpkgs#git
```

### 2. Clone the Repository
Run this command to clone the configuration files and move into the repository directory:

```bash
git clone https://github.com/alessandro-stella/nixos-config.git && cd ~/nixos-config
```

### 3. Build and Apply the Flake Configuration
Run this command to apply both your system and user configurations. Be aware to choose the right settings:

```bash
sudo nixos-rebuild switch --flake .#dekstop
```

```bash
sudo nixos-rebuild switch --flake .#laptop
```
