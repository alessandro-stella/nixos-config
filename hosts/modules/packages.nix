{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim foot git wget curl gnumake gcc clang unzip glib libnotify 
    bc psmisc fzf ntfs3g networkmanagerapplet gsettings-desktop-schemas
  ];

  programs.nix-ld.enable = true;

  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  programs.gdk-pixbuf.modulePackages = with pkgs; [ librsvg ];
}
