{ config, pkgs, inputs, username, dotfilesPath, ...}:

let
  activationPath = pkgs.lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ];
in
{
  imports = [
    ./modules/packages.nix
    ./modules/theming.nix
    ./modules/xdg.nix
    ./modules/activation.nix
    
    ./modules/programs/brave.nix
    ./modules/programs/tmux.nix
    ./modules/programs/zshell.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true; 
}
