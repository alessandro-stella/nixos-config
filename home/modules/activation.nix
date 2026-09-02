{ config, pkgs, username, hostType, dotfilesPath, ... }:
  
let
  activationPath = pkgs.lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ];
in
{
  # Setup Neovim configuration repository
  home.activation.setupNeovim =
  config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH=${activationPath}:$PATH
    ${./bootstrap/setup-neovim.sh}
  ''; 

  # Set symlink for theme changing
  home.activation.themeLinks =
  config.lib.dag.entryAfter [ "write" ] ''
    export PATH=${activationPath}:$PATH
    ${./bootstrap/theme-links.sh}
  '';
}
