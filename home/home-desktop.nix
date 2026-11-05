{ config, pkgs, dotfilesPath, inputs, ... }:

{
  home.packages = (with pkgs; [
    spotify
    discord
    inkscape
    (pkgs.python3.withPackages (ppkgs: [
      ppkgs.openrgb-python
    ]))
  ]) ++ [
    # Adding PhotoCraft as an alternative to Photoshop
    inputs.artcraft.packages.${pkgs.stdenv.hostPlatform.system}.photocraft
  ];
}
