{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    mesa
  ];
}
