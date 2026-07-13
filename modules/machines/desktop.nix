{ pkgs, ... };

{
  environment.systemPackages = with pkgs; [
    spotify
    discord
  ];

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      settings = {
        main = {
          "leftcontrol+leftalt" = "rightalt";
        };
      };
    };
  };
}
