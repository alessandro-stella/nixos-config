{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  # Set device name
  networking.hostName = "desktop-nix";

  # Set bootloader to GRUB
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      useOSProber = true;

      minegrub-world-sel = {
        enable = true;
        customIcons = with config.system; [
          {
            inherit name;
            lineTop = with nixos; distroName + " " + codeName + " (" + version + ")";
            lineBottom = "Survival Mode, No Cheats, Version: " + nixos.release;
            imgName = "nixos";
          }
        ];
      };  
    };

    efi.canTouchEfiVariables = true;
  };

  # Display SDDM only on one monitor
  services.displayManager.sddm = {
    settings = {
      Wayland = {
        CompositorCommand = "${pkgs.weston}/bin/weston --shell=kiosk -c /etc/sddm/weston.ini";
      };
    };
  };

  # Temporarly disable all monitors except the
  # one on which SDDM will be displayed
  environment.etc."sddm/weston.ini".text = ''
    [core]
    backend=drm-backend.so

    [output]
    name=DP-3
    mode=preferred

    [output]
    name=DP-1
    mode=off

    [output]
    name=DP-2
    mode=off

    [output]
    name=HDMI-A-1
    mode=off
  '';

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
 
  # Desktop specific packages
  environment.systemPackages = with pkgs; [
    spotify
    discord
  ];

  # Change shortcut for AltGr
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
}
