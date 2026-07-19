{ config, pkgs, nvim-config, ...}:

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
    btop
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
    rofi

    # Font and icons
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  programs.home-manager.enable = true;

  # Cursor settings
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;

    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Set folders inside .config
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

    "nvim" = {
      source = nvim-config;
      recursive = true;
    };
  }; 

  # Set symlink for theme changing
  home.activation.themeLinks =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      declare -A links=(
        ["$HOME/.config/kitty/colors-kitty.conf"]="kitty.conf"
        ["$HOME/.config/oh-my-posh/themes/current_theme.omp.json"]="oh-my-posh.omp.json"
        ["$HOME/.config/rofi/colors.rasi"]="rofi.rasi"
        ["$HOME/.config/swaync/style.css"]="swaync.css"
        ["$HOME/.config/waybar/style.css"]="waybar.css"
        ["$HOME/.config/wlogout/style.css"]="wlogout.css"
      )

      for target in "''${!links[@]}"; do
        ln -sfn "$HOME/.config/themes/current_theme/''${links[$target]}" "$target"
      done
    '';

  # Set .bashrc file
  home.file.".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/bashrc";
}

