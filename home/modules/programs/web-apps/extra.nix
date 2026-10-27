{ pkgs, makeWebApp, ... }:

let
  icons = {
    teams = pkgs.fetchurl {
      name = "teams.svg";
      url = "https://upload.wikimedia.org/wikipedia/commons/0/07/Microsoft_Office_Teams_%282025%E2%80%93present%29.svg";
      sha256 = "0bi9fxj1w4wl18s9gw8r1dhsha4xvfskl5wnsirygjcgrmwn5chs";
    };

    whatsapp = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/1/19/WhatsApp_logo-color-vertical.svg";
      sha256 = "0z07m0gbxm68m3y7y3z71fry1ypcki8ipgks8lwf61pb6lb0m0jz";
    };
  };
in
{
  xdg.desktopEntries = {
    Teams = makeWebApp "Microsoft Teams" "https://teams.microsoft.com/v2/" icons.teams;
    WhatsApp = makeWebApp "WhatsApp Web" "https://web.whatsapp.com/" icons.whatsapp;
  };
}
