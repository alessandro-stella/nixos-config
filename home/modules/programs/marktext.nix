{ fetchurl, appimageTools, ... }:

let
  pname = "marktext";
  version = "0.23.0";

  src = fetchurl {
    url = "https://github.com/marktext/marktext/releases/download/v${version}/marktext-linux-${version}.AppImage";
    hash = "sha256-QKJpczf+z6PIIUaTM8S0P8vL/fcR6nE2Q+Y4B5pUfNg=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/marktext.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/marktext.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=marktext'
    
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r ${appimageContents}/usr/share/icons $out/share/
    fi
  '';
}
