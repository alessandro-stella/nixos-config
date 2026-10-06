{ pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  
  services.tailscale.enable = true;
  
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
}
