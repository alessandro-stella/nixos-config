{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    spotify
    discord
  ];

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      settings = {
        main = {
          "leftcontrol+leftalt" = "rightalt";
        };
      };
    };
  };

  networking.hostName = "desktop-nix";
}
