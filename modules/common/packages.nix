{ pkgs, ... };

{
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gnumake
    gcc
    unvip
    glib
  ];
}
