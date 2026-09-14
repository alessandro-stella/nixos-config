{ config, lib, pkgs, ... }:

let
  browser = "${pkgs.brave-origin}/bin/brave-origin";

  icons = {
    chatgpt = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/4/46/ChatGPT_Search_logo_Black_Square_-_rounded_corners.svg";
      sha256 = "01g7ci9w2m7ayl8bpjbwnfwcdnl9ypnp07b90582r50li60z7i88";
    };

    claude = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/clawd.png";
      sha256 = "10z0nkf915gp37zl10vy7b91gp4dfr0nv0nkjaypg8iksh5gngsg";
    };
    
    gemini = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/dark/gemini-color.png";
      sha256 = "1nx6gd6mkq0hf3l3cxszv9lgpfb2y1ycxk4zkxdp5a92bpsjiihh";
    };
    
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

  makeWebApp = name: url: iconPath: {
    name = name;
    exec = "${browser} --password-store=basic --app=${url}";
    terminal = false;
    type = "Application";
    icon = "${iconPath}";
    categories = [ "Network" "Chat" ];
  };
in
{
  xdg.desktopEntries = {
    ChatGPT = makeWebApp "ChatGPT" "https://chat.openai.com/" icons.chatgpt;
    Gemini = makeWebApp "Google Gemini" "https://gemini.google.com/" icons.gemini;
    Teams = makeWebApp "Microsoft Teams" "https://teams.microsoft.com/v2/" icons.teams;
    WhatsApp = makeWebApp "WhatsApp Web" "https://web.whatsapp.com/" icons.whatsapp;
    Claude = makeWebApp "Claude" "https://claude.ai/new/" icons.claude;
  };
}
