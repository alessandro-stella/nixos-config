{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Apps
    nautilus
    evince
    loupe
    pavucontrol
    apostrophe
    bruno 

    # Tool CLI
    btop
    fastfetch
    imagemagick
    jq
    tree
    ripgrep
    nodejs
    python3
    tree-sitter
    wakatime-cli
    oh-my-posh

    # Graphical suite
    hyprland
    awww
    swaynotificationcenter
    hyprshot
    cliphist
    wtype
    wl-clipboard
    wallust
    quickshell
    lm_sensors
    zenity
  ];
}
