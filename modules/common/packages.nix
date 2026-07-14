{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gnumake
    gcc
    unzip
    glib
  ];
}
