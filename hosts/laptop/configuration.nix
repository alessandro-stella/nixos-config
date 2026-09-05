{ config, pkgs, username, ... }:

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
  ];

  # Power management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 90;

      DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";
    };
  };

  security.wrappers.tlp = {
    source = "${pkgs.tlp}/bin/tlp";
    setuid = true;
    owner = "root";
    group = "root";
    permissions = "u+s,g+x,o+x";
  }; 

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Disable trackpoint (hardware damage causes drift, I suppose)
  systemd.services.trackpoint-filter = {
    description = "Filter trackpoint drift";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "evsieve-start" ''
        for syspath in /sys/class/input/event*; do
          if grep -q "TPPS/2 Elan TrackPoint" "$syspath/device/name" 2>/dev/null; then
            EVENT_DEV="/dev/input/$(basename "$syspath")"
            break
          fi
        done

        if [ -z "$EVENT_DEV" ]; then
          echo "TrackPoint not found"
          exit 1
        fi

        exec ${pkgs.evsieve}/bin/evsieve \
          --input "$EVENT_DEV" grab \
          --block rel \
          --output name="TrackPoint Buttons Only"
      '';
      Restart = "always";
      RestartSec = "3s";
    };
  };

  # Fingerprint reader 
  services.fprintd = {
    enable = true;
  };

  # Disable PAM and fingerprint interaction 
  security.pam.services = {
    login.fprintAuth = false; 
    su.fprintAuth = false;
    sudo.fprintAuth = false;
    polkit-1.fprintAuth = false;
    ghdm.fprintAuth = false;
    sddm.fprintAuth = false;
    xdg-desktop-portal.fprintAuth = false;
  };

  # Quickshell permissions for fprintd 
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${pkgs.fprintd}/bin/fprintd-verify";
          options = [ "NOPASSWD" "NOEXEC" ];
        }
        {
          command = "${pkgs.fprintd}/bin/fprintd-list";
          options = [ "NOPASSWD" "NOEXEC" ];
        }
        {
          command = "${pkgs.bash}/bin/bash";
          options = [ "NOPASSWD" "NOEXEC" ];
        }
      ];
    }
  ];

  # Udev rules for fingerprint 
  services.udev.extraRules = ''
    # Fingerprint reader - make accessible to 'input' group
    SUBSYSTEMS=="usb", KERNEL=="*", ATTRS{type}=="*", TAG="uaccess"
    SUBSYSTEM=="input", KERNEL=="event*", TAG="uaccess"
  '';

  users.groups.input.members = [ username ];

  # Polkit rules to allow quickshell to call fprintd
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "net.reactivated.Fingerprint.Device.VerifyStart" ||
           action.id == "net.reactivated.Fingerprint.Device.ListStart") &&
          subject.user == "${username}") {
        return polkit.Result.YES;
      }
    });
  '';
}

