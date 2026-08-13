{ config, pkgs, username, ... }:

let
  dotfilesPath = "/home/${username}/nixos-config/home/dotfiles";
in
{
  home.packages = with pkgs; [
    swi-prolog
  ];
}
