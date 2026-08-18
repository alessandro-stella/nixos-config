{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
    ../gpu/intel.nix
  ];

  # Set device name
  networking.hostName = "thinkpad-t14";

  # Set bootloader to systemd
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };

    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
    networkmanagerapplet
  ];

  # Power management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 90;
    };
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Tailscale integration
  services.tailscale.enable = true;

  # Fingerprint reader 
  # services.fprintd.enable = true;

  # security.polkit.extraConfig = ''
  #  polkit.addRule(function(action, subject) {
  #    if (action.id == "net.reactivated.fprint.device.enroll" && subject.isInGroup("wheel")) {
  #      return polkit.Result.YES;
  #    }
  #  });
  # '';

  # Change order of fingerprint scanner to AFTER sudo prompt
  # security.pam.services.sudo.rules.auth.fprintd.order = config.security.pam.services.sudo.rules.auth.unix.order + 50;
}
