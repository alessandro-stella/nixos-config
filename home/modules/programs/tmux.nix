{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Prefix: Ctrl+x
    shortcut = "x";
    
    baseIndex = 1;
    escapeTime = 0;
    secureSocket = false;
    mouse = false;
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
      set -g default-terminal "tmux-256color"
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

      # Change message style
      set -g message-style "fg=default,bg=default"

      # Hide status bar when the window runs Neovim
      set-hook -g after-select-window 'if-shell -F "#{==:#{pane_current_command},nvim}" "set status off" "set status on"'
    '';
  };
}
