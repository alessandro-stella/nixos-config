{ config, pkgs, inputs, ...}:

let
  dotfilesPath = "/home/alessandro/nixos-config/home/alessandro/dotfiles";
in
{
  home.username = "alessandro";
  home.homeDirectory = "/home/alessandro";
  home.stateVersion = "26.05";

  fonts.fontconfig.enable = true;

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
  home.activation.setupNeovim = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_DIR="$HOME/.config/nvim"
    REPO_URL="https://github.com/alessandro-stella/OrionVim.git"

    if [ ! -d "$NVIM_DIR/.git" ]; then
      echo "Cloning OrionVim..."
      rm -rf "$NVIM_DIR"
      ${pkgs.git}/bin/git clone "$REPO_URL" "$NVIM_DIR"
    else
      echo "OrionVim already installed, checking updates..."
      ${pkgs.git}/bin/git -C "$NVIM_DIR" pull || echo "Failed to update Neovim: no internet connection."
    fi
  '';

  # Synchronize wallpapers repository
  home.activation.setupWallpapers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PICS_DIR="$HOME/Pictures"
    WP_DIR="$PICS_DIR/wallpapers"
    REPO_URL="https://github.com/alessandro-stella/linux-wallpapers.git" 

    mkdir -p "$PICS_DIR"

    if [ ! -d "$WP_DIR/.git" ]; then
      echo "Downloading wallpapers..."
      rm -rf "$WP_DIR"
      ${pkgs.git}/bin/git clone "$REPO_URL" "$WP_DIR"
    else
      echo "Wallpaper folder exists, checking for updates..."
      ${pkgs.git}/bin/git -C "$WP_DIR" pull || echo "Failed to update wallpapers: no internet connection."
    fi
  '';

  # Set symlink for theme changing
  home.activation.themeLinks =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      declare -A links=(
        ["$HOME/.config/kitty/colors-kitty.conf"]="kitty.conf"
        ["$HOME/.config/oh-my-posh/themes/current_theme.omp.json"]="oh-my-posh.omp.json"
        ["$HOME/.config/rofi/colors.rasi"]="rofi.rasi"
        ["$HOME/.config/swaync/style.css"]="swaync.css"
        ["$HOME/.config/waybar/style.css"]="waybar.css"
        ["$HOME/.config/wlogout/style.css"]="wlogout.css"
        ["$HOME/.config/hypr/modules/dynamic-border.lua"]="dynamic-border.lua"
      )

      for target in "''${!links[@]}"; do
        ln -sfn "$HOME/.config/themes/current_theme/''${links[$target]}" "$target"
      done
    '';

    
  # Unlock theme folder to SDDM
  home.activation.fixSddmPermissions = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    chmod +x "$HOME"
    chmod +x "$HOME/.config"
    chmod +x "$HOME/.config/themes"
    
    if [ -f "$HOME/.config/themes/current_theme" ]; then
      chmod +r "$HOME/.config/themes/current_theme"
      echo "Theme permissions updated successfully"
    fi
  '';

  # Create custom files for hyprland
  home.activation.setupHyprModules = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    MODULES_DIR="$HOME/.config/hypr/modules"
    
    mkdir -p "$MODULES_DIR"
  
    create_if_missing() {
      local target=$1
      local template=$2
      
      if [ ! -f "$target" ]; then
        echo "Module missing, creating: $target"
        cp "$template" "$target"
        chmod 644 "$target"
      else
        echo "Module $target exists, skipping"
      fi
    }
  
    create_if_missing "$MODULES_DIR/custom-keybinds.lua" "${./dotfiles/hypr/templates/custom-keybinds.lua}"
    create_if_missing "$MODULES_DIR/device-settings.lua" "${./dotfiles/hypr/templates/device-settings.lua}"
    create_if_missing "$MODULES_DIR/monitors.lua"        "${./dotfiles/hypr/templates/monitors.lua}"
  '';

  # Set .bashrc file
  home.file.".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/bashrc";
}

