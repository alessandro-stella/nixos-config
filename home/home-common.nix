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
  programs.home-manager.enable = true; 

  # Installed packages
  home.packages = with pkgs; [
    # Testing
    foot

    # Apps
    nautilus
    kitty
    evince
    loupe
    pavucontrol
    apostrophe
    bruno 

    # Tool CLI
    btop
    fastfetch
    imagemagick
    jq
    tree
    ripgrep
    nodejs
    python3
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
  ];

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

    "foot".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/foot";
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
  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink ./zshrc;

  # Configure tmux
  programs.tmux = {
    enable = true;

    # Prefix: Ctrl+x
    shortcut = "x";

    baseIndex = 1;
    escapeTime = 0;
    secureSocket = false;
    mouse = true;
    historyLimit = 50000;
    
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.minimal-tmux-status;
        extraConfig = ''
          # Status bar
          set -g @minimal-tmux-status "top"
          set -g @minimal-tmux-justify "centre"
          set -g @minimal-tmux-left false
          set -g @minimal-tmux-right false

          # Current window indicator
          set -g @minimal-tmux-use-arrow true
          set -g @minimal-tmux-right-arrow ""
          set -g @minimal-tmux-left-arrow ""
        '';
      }
    ];

    extraConfig = ''
      # Terminal settings
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Toggle status bar
      bind-key b set-option status

      # Prevent automatic window renaming
      set-option -g allow-rename off

      # Create a new window in the current directory
      bind c new-window -c "#{pane_current_path}"

      # Close the current window
      bind x kill-window

      # Kill the entire session
      bind X confirm-before -p "Kill entire session? (y/n)" kill-session

      # Move between windows
      bind n next-window
      bind p previous-window

      # Do not attach to another session when the current session is destroyed
      set-option -g detach-on-destroy on 

      # Reload configuration
      bind r source-file ~/.config/tmux/tmux.conf \; \
        display-message "tmux configuration reloaded"

        set -g message-style "fg=white,bg=default"
    '';
  };
}
