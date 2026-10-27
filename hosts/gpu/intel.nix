{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  boot.initrd.kernelModules = [ "i915" ];
}
