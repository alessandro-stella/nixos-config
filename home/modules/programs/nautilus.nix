{ pkgs, ... }:

{
  home.packages = [ pkgs.nautilus ];

  dconf.settings = {
    "org/freedesktop/tracker/miner/files" = {
      ignored-directories = [
        "node_modules"
        ".venv"
        "target"
        "build"
        "dist"
        ".git"
      ];
    };
  };
}
