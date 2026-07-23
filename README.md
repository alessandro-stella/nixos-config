# NixOS Hyprland Flake Configuration

This repository contains my personal system and user configurations managed via Nix Flakes. Moreover, this configurations is thought for one user only, so you'll need to handle that as it's explained next.
WARNING: there are still some bugs that needs to be figured out, such as no wallpaper on the first installation (run the theme changer to fix that)

## Important!!!
This configuration aims to replicate my custom settings, therefore some of the configuration might not work. The most important settings to watch out are the bootloader and the graphical settings for SDDM:

### Bootloader
On the laptop configuration, as I only use NixOS, I didn't include an option for dual boot, so i left the default ```systemd-boot```. On my desktop, as I dual boot Windows and NixOS, i added ```GRUB``` to customize the experience. I suppose you're at least a bit familiar with the Linux ecosystem (or else you'd be crazy to go straight to NixOS), so I didn't include an additional option to change this; I trust that you'll be more than capable to change the configuration after a first install to better suit your needs.

### SDDM
On my desktop I have two monitors and a sensor panel, but SDDM decided to show only on one monitor. Obviously it chose the wrong one, so inside the desktop configuration I had to change the output for it to obtain the right behavior. You'll need to change this too to avoid having future problems with the greeter.

<br>

## Preliminary steps
This configuration starts from a fresh install after choosing "No desktop" during NixOS installation. If you're not connected to Internet, launch ```nmtui``` and connect to a WiFi. 

### 1. Enter a Nix Shell with Git
Run this to drop into a temporary shell with Git working:

```bash
nix shell nixpkgs#git --extra-experimental-features "nix-command flakes"
```

### 2. Clone the Repository
Run this command to clone the configuration files and move into the repository directory:

```bash
git clone https://github.com/alessandro-stella/nixos-config.git && cd ~/nixos-config
```

### 3. Set your username
Edit ```flake.nix``` by changing the variable ```username``` to suit your wanted username.

<br>

## Installation.
This setup is able to differentiate between a laptop or a desktop installation. Be aware to change "desktop" to "laptop" in the following commands to reflect your choice.

### 1. Generate ```hardware-configuration.nix```

```bash
sudo nixos-generate-config --show-hardware-config > hosts/<HOST>/hardware-configuration.nix
```

### 2. Force Git to index untracked hardware configuration
```bash
git add -f -N hosts/<HOST>/hardware-configuration.nix && git update-index --assume-unchanged hosts/<HOST>/hardware-configuration.nix
```

### 3. Build and apply the flake configuratio:

```bash
sudo nixos-rebuild switch --flake .#<HOST>
```

### 4. Reboot the system and enjoy!

```bash
reboot
```

<br>

## Custom build command
Instead of using the very verbose ```sudo nixos-rebuild switch --flake .#<HOST>``` to rebuild the system, there's a very useful custom command: ```nix-build <HOST>```.
This greatly improves the usability of the system, as it both shortens the actual command to write and eliminates the verbosity of NixOS errors by only keeping the useful parts.
