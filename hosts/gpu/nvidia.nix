{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;

    # Allow suspention
    powerManagement.enable = true;
    powerManagement.kernelSuspendNotifier = false;

    # Use only on newer gpus
    open = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';
}
