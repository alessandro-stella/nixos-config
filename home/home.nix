{ config, pkgs, inputs, username, ...}:

let
  dotfilesPath = "/home/${username}/nixos-config/home/dotfiles";

  activationPath = pkgs.lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ];
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";


  home.packages = with pkgs; [
    # Apps
    nautilus
    kitty
    evince
    loupe
    pavucontrol
    apostrophe

    # Tool cli
    btop
    fastfetch
    jq
    tree
    ripgrep
    nodejs
    tree-sitter
    wakatime-cli
    neovim
    oh-my-posh

    # Graphical suite
    hyprland
    awww
    swaynotificationcenter
    swaylock-effects
    wlogout
    hyprshot
    cliphist
    wtype
    wl-clipboard
    wallust
    waybar
    rofi

    # Font and icons
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  programs.home-manager.enable = true;

  # Default font settings
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" ];
  };

  # Setting brave-origin
  programs.brave = {
    enable = true;
    package = inputs.brave-origin.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # Cursor settings
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;

    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Dark theme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Set folders inside .config
  xdg.configFile = {
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/fastfetch";
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
    "kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/kitty";
    "oh-my-posh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/oh-my-posh";
    "rofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/rofi";
    "swaylock".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaylock";
    "swaync".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaync";
    "themes".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/themes";
    "wallust".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wallust";
    "waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/waybar";
    "wlogout".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wlogout";

    "scripts".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/scripts";
  }; 

  # Setup Neovim configuration repository
  home.activation.setupNeovim =
  config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH=${activationPath}:$PATH
    ${./scripts/setup-neovim.sh}
  ''; 

  # Set symlink for theme changing
  home.activation.themeLinks =
  config.lib.dag.entryAfter [ "write" ] ''
    export PATH=${activationPath}:$PATH
    ${./scripts/theme-links.sh}
  '';

  # Synchronize wallpapers repository and generate thumbnails
  home.activation.setupWallpapers =
  config.lib.dag.entryAfter [ "linkGeneration" ] ''
    export PATH=${activationPath}:$PATH
    ${./scripts/setup-wallpapers.sh}
  '';
    
  # Allow SDDM to read current theme
  home.activation.fixSddmPermissions =
  config.lib.dag.entryAfter [ "linkGeneration" ] ''
    export PATH=${activationPath}:$PATH
    ${./scripts/fix-sddm-permissions.sh} ${username}
  '';

  # Create custom files for hyprland
  home.activation.setupHyprModules =
  config.lib.dag.entryAfter [ "linkGeneration" ] ''
    export PATH=${activationPath}:$PATH
    export TEMPLATE_DIR="${dotfilesPath}/hypr/templates"
    ${./scripts/setup-hypr-modules.sh}
  '';

  # Set .bashrc file
  home.file.".bashrc".source = config.lib.file.mkOutOfStoreSymlink ./bashrc;
}
