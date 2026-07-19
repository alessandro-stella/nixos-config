{ config, pkgs, ... }:

let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "pixie-better";
    src = ../home/ale-nix/dotfiles/sddm-theme;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/pixie-better
      cp -R ./* $out/share/sddm/themes/pixie-better
    '';
  };
in
{
  imports = [ ];

  # Generic configurations
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };

    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  security.polkit.enable = true;

  # Locale and language settings
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Keyboard
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };
  console.keyMap = "it";

  programs.nix-ld.enable = true;

  # Font and icons
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  # Hyprland
  programs.hyprland.enable = true;

  # SDDM settings
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;
      theme = "pixie-better";
    };

    defaultSession = "hyprland";
  };
  
  systemd.tmpfiles.rules = [
    "A /home/ale-nix - - - - u:sddm:x"
    "A /home/ale-nix/.config - - - - u:sddm:x"
    "A /home/ale-nix/.config/themes - - - - u:sddm:x"
 
    "A /home/ale-nix/.config/themes/current_theme - - - - u:sddm:rx"
  ];

  # User settings
  users.users."ale-nix" = {
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gnumake
    gcc
    unzip
    glib

    sddmTheme
  ];

  # Keep last 5 system generations
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-generations +5";
  };

  # Add support for svg
  programs.gdk-pixbuf.modulePackages = with pkgs; [
    librsvg
  ];

  # Disable xterm
  services.xserver.excludePackages = [ pkgs.xterm ];

  # Turn on experimental commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
