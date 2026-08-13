{ config, pkgs, username, ... }:

let
  dotfilesPath = "/home/${username}/nixos-config/home/dotfiles";
in
{
  home.packages = with pkgs; [
    spotify
    discord
    gimp
  ];

  # Adding configuration for PhotoGimp
  xdg.configFile."GIMP/3.2".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/photogimp/custom-GIMP";

  xdg.dataFile."applications" = {
    source = ./dotfiles/photogimp/files-inside-local/share/applications;
    recursive = true;
  };

  xdg.dataFile."icons" = {
    source = ./dotfiles/photogimp/files-inside-local/share/icons;
    recursive = true;
  };
}
