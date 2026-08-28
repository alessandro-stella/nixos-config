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
  # Use system hardware configuration
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    foot

    git
    wget
    curl
    gnumake
    gcc
    clang
    unzip
    glib
    libnotify
    bc
    psmisc
    fzf
    ntfs3g
    networkmanagerapplet

    polkit_gnome
    (writeShellScriptBin "start-polkit" ''
    exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '')

    sddmTheme
  ];

  # Set tmp files to be saved in RAM
  boot.tmp.useTmpfs = true;

  # Add NTFS to filesystems
  boot.supportedFilesystems = [ "ntfs-3g" ];

  # Avoid using ntfs3
  boot.blacklistedKernelModules = [ "ntfs3" ];

  # Various safety features
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

  # Font settings
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
    };

    antialias = true;

    hinting = {
      enable = true;
      style = "slight";
    };

    subpixel.rgba = "none";
  };

  # Unpatched binaries
  programs.nix-ld.enable = true;

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

  # Extra sudo settings
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
      Defaults insults
    '';
  };

  # User settings
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;

    extraGroups = [
      "wheel"
      "networkmanager"
      "wireshark"
    ];
  };

  # Zshell configuration
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Enable graphics
  hardware.graphics.enable = true;

  # External storage device settings
  services.udisks2.enable = true;
  services.gvfs.enable = true; 

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

  # Current nix version 
  system.stateVersion = "26.05";
}

