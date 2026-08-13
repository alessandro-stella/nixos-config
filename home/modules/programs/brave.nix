{ inputs, pkgs, ... }:

{
  programs.brave = {
    enable = true;
    package = inputs.brave-origin.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
