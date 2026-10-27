{ pkgs, makeWebApp, ... }:

let
  icons = {
    word = pkgs.fetchurl {
      name = "word.svg";
      url = "https://upload.wikimedia.org/wikipedia/commons/e/e8/Microsoft_Office_Word_%282025%E2%80%93present%29.svg";
      hash = "sha256-1ZqxxkgHGJtuwOtTgevHr2gC+WWs5Emc25TsnU/7DQk=";
    };

    excel = pkgs.fetchurl {
      name = "excel.svg";
      url = "https://upload.wikimedia.org/wikipedia/commons/6/60/Microsoft_Office_Excel_%282025%E2%80%93present%29.svg";
      hash = "sha256-Sf4MubwrkWkoyAkR/MxRhFhXK1e2aDYEZJR63Skrl3o=";
    };

    powerpoint = pkgs.fetchurl {
      name = "powerpoint.svg";
      url = "https://upload.wikimedia.org/wikipedia/commons/d/df/Microsoft_Office_PowerPoint_%282025%E2%80%93present%29.svg";
      hash = "sha256-TaHkY2Wvrbh24Hx1nmgNY9vDFBKI0k6OvSMe6U7hxvQ=";
    };
  };
in
{
  xdg.desktopEntries = {
    Word = makeWebApp "Microsoft Word" "https://word.cloud.microsoft/" icons.word;
    Excel = makeWebApp "Microsoft Excel" "https://excel.cloud.microsoft/" icons.excel;
    PowerPoint = makeWebApp "Microsoft PowerPoint" "https://powerpoint.cloud.microsoft/" icons.powerpoint;
  };
}
