{ pkgs, makeWebApp, ... }:

let
  icons = {
    claude = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/clawd.png";
      sha256 = "10z0nkf915gp37zl10vy7b91gp4dfr0nv0nkjaypg8iksh5gngsg";
    };
    
    gemini = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/dark/gemini-color.png";
      sha256 = "1nx6gd6mkq0hf3l3cxszv9lgpfb2y1ycxk4zkxdp5a92bpsjiihh";
    };
  };
in
{
  xdg.desktopEntries = {
    Claude = makeWebApp "Claude" "https://claude.ai/new/" icons.claude;
    Gemini = makeWebApp "Google Gemini" "https://gemini.google.com/" icons.gemini;
  };
}
