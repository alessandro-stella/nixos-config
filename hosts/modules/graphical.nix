{ pkgs, username, ... }:

let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "pixie-better";
    src = ../../home/dotfiles/sddm-theme;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/pixie-better
      substituteInPlace theme.conf \
        --replace-fail "@THEME_BACKGROUND@" \
        "/var/lib/current-theme/wallpaper.png"
      cp -R ./* $out/share/sddm/themes/pixie-better
    '';
  };
in
{
  hardware.graphics.enable = true;
  security.polkit.enable = true;

  # X server and keyboard
  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
    xkb = { layout = "it"; variant = ""; };
  };

  # Hyprland
  programs.hyprland.enable = true;

  # SDDM
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "pixie-better";
    };
    defaultSession = "hyprland";
  };

  # SDMM wallpaper
  systemd.paths.sddm-wallpaper-seed = {
    description = "Monitor changes for SDDM";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/home/${username}/.config/themes/current_theme/name";
    };
  };
  
  systemd.services.sddm-wallpaper-seed = {
    description = "Seed SDDM wallpaper and accents, clear cache if changed";
    wantedBy = [ "graphical.target" ];
    before = [ "display-manager.service" ]; 
    path = with pkgs; [ coreutils diffutils ];
    
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sddm-wallpaper-seed" ''
        SRC_WALLPAPER="/home/${username}/.config/themes/current_theme/wallpaper.png"
        DEST_WALLPAPER="/var/lib/current-theme/wallpaper.png"
        SRC_ACCENTS="/home/${username}/.config/themes/current_theme/AccentsSDDM.qml"
        DEST_ACCENTS="/var/lib/current-theme/AccentsSDDM.qml"

        mkdir -p /var/lib/current-theme
        CHANGED=0

        if [ -f "$SRC_WALLPAPER" ] && ! cmp -s "$SRC_WALLPAPER" "$DEST_WALLPAPER"; then
          cp -f "$SRC_WALLPAPER" "$DEST_WALLPAPER"
          CHANGED=1
        fi

        if [ -f "$SRC_ACCENTS" ] && ! cmp -s "$SRC_ACCENTS" "$DEST_ACCENTS"; then
          cp -f "$SRC_ACCENTS" "$DEST_ACCENTS"
          CHANGED=1
        fi

        if [ "$CHANGED" -eq 1 ]; then
          rm -rf /var/lib/sddm/.cache
          rm -rf "/home/${username}/.cache/sddm-greeter-qt6"
        fi
      '';
    };
  };

  # XDG Portals
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = [ "hyprland" "gtk" ];
  }; 
  systemd.user.services.xdg-desktop-portal = {
    unitConfig = { Requires = [ "graphical-session.target" ]; Wants = [ "graphical-session.target" ]; After = [ "graphical-session.target" ]; };
  };

  # Font
  fonts.packages = with pkgs; [ font-awesome nerd-fonts.jetbrains-mono ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
    antialias = true;
    hinting = { enable = true; style = "slight"; };
    subpixel.rgba = "none";
  };

  # Nautilus indicization
  programs.dconf.enable = true;
  services.gnome.localsearch.enable = true;
  services.gnome.tinysparql.enable = true;

  # Graphical packages for polkit authorization
  environment.systemPackages = with pkgs; [
    polkit_gnome
    (writeShellScriptBin "start-polkit" ''exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1'')
    sddmTheme
  ];
}
