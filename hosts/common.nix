{ config, pkgs, ... }:

{
  imports = [ ];

  # Generic configurations
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  } 

  # Keyboard
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };
  console.keyMap = "it";

  programs.nix-ld.enable = true;

  # Hyprland
  programs.hyprland.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;
    };

    defaultSession = "hyprland";
  };

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
  ];

  # Keep last 5 system generations
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-generations +5";
  };

  # Turn on experimental commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
