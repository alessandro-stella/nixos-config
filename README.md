# NixOS Hyprland Flake Configuration

This repository contains my personal system and user configurations managed via Nix Flakes, including an automated theme and wallpaper switching pipeline optimized to preserve symbolic links.

## Quick Start

Execute these separate steps to clone the repository and deploy the configuration using Nix Flakes.

### 1. Enter a Nix Shell with Git
If you are on a fresh installation and do not have Git installed globally, run this to drop into a temporary shell:

```bash
nix shell nixpkgs#git --extra-experimental-features "nix-command flakes"
```

### 2. Clone the Repository
Run this command to clone the configuration files and move into the repository directory:

```bash
git clone [https://github.com/alessandro-stella/nixos-config.git](https://github.com/alessandro-stella/nixos-config.git) ~/nixos-config && cd ~/nixos-config
```

### 3. Generate hardware-configuration.nix
Be aware to change "desktop" to "laptop" if needed:

```bash
mkdir -p hosts/desktop && sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
```

### 4. Force Git to Index Untracked Hardware Configuration
Run this to allow Nix Flakes to see the newly generated hardware configuration without tracking future changes on it:

```bash
git add -f hosts/desktop/hardware-configuration.nix && git update-index --assume-unchanged hosts/desktop/hardware-configuration.nix
```

### 5. Build and Apply the Flake Configuration
Run the command matching your target host to apply both your system and user configurations:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

### 6. Reboot the system and enjoy!

```bash
reboot
```
