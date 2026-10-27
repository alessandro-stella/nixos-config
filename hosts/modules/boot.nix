{ pkgs, ... }:

let
  theme = pkgs.runCommand "plymouth-nixlogo"
    { nativeBuildInputs = [ pkgs.imagemagick ]; }
    ''
      d=$out/share/plymouth/themes/nixlogo
      mkdir -p $d
      magick ${./nix-logo.png} -resize 300x $d/logo.png

      cat > $d/nixlogo.plymouth <<EOF
      [Plymouth Theme]
      Name=nixlogo
      ModuleName=script

      [script]
      ImageDir=$d
      ScriptFile=$d/nixlogo.script
      EOF

      cat > $d/nixlogo.script <<'EOF'
      Window.SetBackgroundTopColor(0, 0, 0);
      Window.SetBackgroundBottomColor(0, 0, 0);
      logo = Image("logo.png");
      s = Sprite(logo);
      s.SetX(Window.GetWidth() / 2 - logo.GetWidth() / 2);
      s.SetY(Window.GetHeight() / 2 - logo.GetHeight() / 2);
      EOF
    '';
in
{
  boot = {
    plymouth = {
      enable = true;
      themePackages = [ theme ];
      theme = "nixlogo";
    };

    initrd.systemd.enable = true;
    initrd.verbose = false;
    consoleLogLevel = 0;

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "udev.log_level=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];
  };
}
