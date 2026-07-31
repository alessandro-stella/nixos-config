{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;

    # Use only on newer gpus
    open = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
