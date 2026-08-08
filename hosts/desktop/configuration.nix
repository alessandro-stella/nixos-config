{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../gpu/nvidia.nix
  ];

  # Set device name
  networking.hostName = "desktop-nix";

  # Set bootloader to GRUB
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];

      default = "saved";
      useOSProber = true;

      extraInstallCommands = ''
        {
        echo 'menuentry "UEFI Firmware Settings" --class uefi {'
        echo '  fwsetup'
        echo '}'
        } >> /boot/grub/grub.cfg
      '';

      minegrub-world-sel = {
        enable = true;
        customIcons = with config.system; [
          {
            inherit name;
            lineTop = with nixos; distroName + " (" + version + ")";
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

  # Fix for instant wakeup from suspension
  systemd.services.disable-acpi-wakeup = {
    description = "Disable all ACPI devices for wakeup";
    wantedBy = [ "multi-user.target" ];
    script = ''
      for dev in $(${pkgs.coreutils}/bin/cat /proc/acpi/wakeup | ${pkgs.gnugrep}/bin/grep enabled | ${pkgs.gawk}/bin/awk '{print $1}'); do
          echo $dev > /proc/acpi/wakeup
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
