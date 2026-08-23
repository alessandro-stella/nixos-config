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
    swaylock-effects
    wlogout
    hyprshot
    cliphist
    wtype
    wl-clipboard
    wallust
    waybar
    rofi

    # TESTING
    quickshell
    lm_sensors
  ];
}
