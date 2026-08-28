{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    swi-prolog
  ];

  xdg.configFile."wireplumber/wireplumber.conf.d/51-rename.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.description = "400 Series Chipset Family On-Package HD Audio Speaker"
          }
        ]
        actions = {
          update-props = {
            node.description = "Laptop Speakers"
          }
        }
      }
      {
        matches = [
          {
            node.description = "400 Series Chipset Family On-Package HD Audio HDMI / DisplayPort 1 Output"
          }
        ]
        actions = {
          update-props = {
            node.description = "HDMI Output"
          }
        }
      }
      {
        matches = [
          {
            node.description = "400 Series Chipset Family On-Package HD Audio Digital Microphone"
          }
        ]
        actions = {
          update-props = {
            node.description = "Integrated microphone"
          }
        }
      }
    ]
  '';
}
