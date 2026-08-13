{ config, pkgs, dotfilesPath, ... }:

{
  home.packages = with pkgs; [
    spotify
    discord
    gimp
  ];

  # Configuration for PhotoGimp
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
