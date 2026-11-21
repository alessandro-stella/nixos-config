{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Apps
    evince
    loupe
    pavucontrol
    bruno
    brave-origin
    qsynth

    # Tool CLI
    btop
    fastfetch
    imagemagick
    jq
    tree
    ripgrep
    nodejs
    tree-sitter
    wakatime-cli
    oh-my-posh
    pandoc
    texliveFull

    # Graphical suite
    hyprland
    awww
    swaynotificationcenter
    hyprshot
    cliphist
    wtype
    wl-clipboard
    pywal
    quickshell
    lm_sensors
    zenity

    # Custom installations
    (pkgs.callPackage ./programs/marktext.nix { })
  ];
}
