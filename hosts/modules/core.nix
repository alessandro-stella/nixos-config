{ pkgs, username, ... }:

{
  system.stateVersion = "26.05";

  # Boot and filesystem
  boot.tmp.useTmpfs = true;
  boot.supportedFilesystems = [ "ntfs-3g" ];
  boot.blacklistedKernelModules = [ "ntfs3" ];
  services.udisks2.enable = true;
  services.gvfs.enable = true; 

  # Language and timezone
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  console.keyMap = "it";

  # User
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "wireshark" ];
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Security
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
      Defaults insults
    '';
  };

  # Nix cleanup
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-generations +5";
  };

  # Additional setup for flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
