{ ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    
    ./modules/core.nix
    ./modules/network.nix
    ./modules/graphical.nix
    ./modules/packages.nix
  ];
}
