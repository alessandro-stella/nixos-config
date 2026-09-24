{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zoxide 
  ];

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
}
