{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "thinkpad-t14";

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ];

  services.tlp = {
    enable = true;

    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "powersave";
  }
}

