{ pkgs, ... }:

let
  browser = "${pkgs.brave-origin}/bin/brave-origin";

  makeWebApp = name: url: iconPath: {
    inherit name;
    exec = "${browser} --password-store=basic --app=${url}";
    terminal = false;
    type = "Application";
    icon = "${iconPath}";
  };
in
{
  imports = [
    ./web-apps/AI.nix
    ./web-apps/extra.nix
    ./web-apps/office.nix
  ];

  _module.args = { inherit browser makeWebApp; };
}
