{ config, pkgs, ...}:

let
  dotfilesPath = "/home/ale-nix/nixos-config/home/ale-nix/dotfiles";
in
{
  home.username = "ale-nix";
  home.homeDirectory = "/home/ale-nix";
  home.stateVersion = "26.05";

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Apps
    brave
    localsend
    nautilus
    kitty

    # Tool cli
    fastfetch
    jq
    tree
    ripgrep
    nodejs
    tree-sitter
    wakatime-cli
    neovim
    oh-my-posh

    # Theming
    adw-gtk3
    adwaita-icon-theme

    # Graphical suite
    hyprland
    awww
    swaynotificationcenter
    swaylock-effects
    wlogout
    hyprshot
    cliphist
    wtype
    wl-clipboard
    wallust
    waybar

    # Font and icons
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  programs.home-manager.enable = true;

  xdg.configFile = {
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/fastfetch";
    "gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/gtk-3.0";
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
    "kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/kitty";
    "oh-my-posh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/oh-my-posh";
    "rofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/rofi";
    "swaylock".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaylock";
    "swaync".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaync";
    "themes".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/themes";
    "wallust".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wallust";
    "waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/waybar";
    "wlogout".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wlogout";
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    HYPRCURSSOR_THEME = "Adwaita";
    HYPRCURSSOR_SIZE = "24";

    EDITOR = "nvim";
    VISUAL = "nvim";

    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
  }; 
}
