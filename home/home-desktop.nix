{ config, pkgs, dotfilesPath, inputs, ... }:

{
  home.packages = (with pkgs; [
    spotify
    discord
    inkscape
  ]) ++ [
    # Adding PhotoCraft as an alternative to Photoshop
    inputs.artcraft.packages.${pkgs.stdenv.hostPlatform.system}.photocraft
  ];
}
