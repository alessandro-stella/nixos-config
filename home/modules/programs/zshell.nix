{ config, pkgs, dotfilesPath, ... }:

{
  home.packages = with pkgs; [
    gum 
  ];

  programs.zsh = {
    enable = true;
    
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    initContent = ''
      PROMPT_EOL_MARK=
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
      export EDITOR="nvim"

      # Binding for Ctrl + Arrow keys
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word


      # Shorthand to compile C/C++ files
      compile() {
        if [ -z "$1" ]; then
          echo "Error: you must specify a source file to compile."
          return 1
        fi

        local src="$1"
        shift
        local extra_flags=("$@")
        local ext="''${src##*.}"
        local base=$(basename "$src" ".$ext")
        
        case "$ext" in
          c) gcc "$src" -o "$base" "''${extra_flags[@]}" ;;
          cpp|cc|cxx|c++) g++ "$src" -o "$base" "''${extra_flags[@]}" ;;
          m) gcc "$src" -o "$base" -lobjc "''${extra_flags[@]}" ;;
          mm) g++ "$src" -o "$base" -lobjc "''${extra_flags[@]}" ;;
          *) echo "Error: unsupported file extension '$ext'"; return 2 ;;
        esac
      }


      # Rebuild NixOS flake
      nixos-switch() {
        if [ -z "$1" ]; then
          gum log --structured --level error "Specify flake name" example "nixos-switch desktop"
          return 1
        fi

        local flake_name="$1"

        gum log --level info "Preparing rebuild..."

        if ! sudo -n true 2>/dev/null; then
          if ! sudo -v; then
            return 1
          fi
        fi

        local outfile=$(mktemp)

        if gum spin --spinner dot --title "Building NixOS ($flake_name)..." -- \
          bash -c "set -o pipefail; sudo nixos-rebuild switch --flake '.#$flake_name' --impure 2>&1 | tee '$outfile'"; then
        
          echo ""
          gum log --level info "✓ Build completed successfully!"
          rm -f "$outfile"
          return 0
        else
          local exit_code=$?
          echo ""
          gum log --structured --level error "Build failed," cmd "sudo nixos-rebuild switch --flake .#$flake_name --impure"

          echo ""
          local err_excerpt
          err_excerpt=$(awk '
            /^[[:space:]]*error:/ { capture=1; buf="" }
            capture { buf = buf $0 "\n" }
            END { printf "%s", buf }
          ' "$outfile")

          if [ -n "$err_excerpt" ]; then
            echo "Error:"
            echo "$err_excerpt" | gum format
            local logfile="/tmp/nixos-switch-last-error.log"
            cp "$outfile" "$logfile"
            echo ""
            gum log --level debug "Full log saved to: $logfile"
          else
            cat "$outfile" | gum format
          fi

          rm -f "$outfile"
          return "$exit_code"
        fi
      }


      # Oh My Posh
      eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/themes/current_theme.omp.json)"

      # Fastfetch
      if command -v fastfetch >/dev/null; then
        fastfetch -c ~/.config/fastfetch/config.jsonc
      fi

      # TEST!!!
    '';
  };
}
