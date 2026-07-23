{ pkgs, username, ... }:

let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "pixie-better";
    src = ../home/dotfiles/sddm-theme;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/pixie-better

      substituteInPlace theme.conf \
        --replace-fail "@THEME_BACKGROUND@" \
        "/home/${username}/.config/themes/current_theme/wallpaper.png"

      cp -R ./* $out/share/sddm/themes/pixie-better
    '';
  };
in
{
  # Set tmp files to be saved in RAM
  boot.tmp.useTmpfs = true;

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

  # Unpatched binaries
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
      wayland.enable = true;
      theme = "pixie-better";
    };

    defaultSession = "hyprland";
  };

  # User settings
  users.users.${username} = {
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "wireshark"
    ];
  };

  # Generical graphic drivers 
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver 
      libvdpau-va-gl
    ];
  };

  # External storage device settings
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gnumake
    gcc
    unzip
    glib
    libnotify
    bc
    psmisc

    sddmTheme
  ];

  # Setting up java
  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  # Add localsend
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

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

  # Install wireshark
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # Disable xterm
  services.xserver.excludePackages = [ pkgs.xterm ];

  # Turn on experimental commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
