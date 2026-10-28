{ config, pkgs, dotfilesPath, hostType, ... }:

let
  customGum = import ./gum.nix { inherit pkgs; };

  compileCommand = ''
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
  '';

  nixosSwitchCommand = ''
    nixos-apply() {
      if [ ! -f "flake.nix" ]; then
        gum log --structured --level warn "No flake.nix found in the current directory," path "$(pwd)"
        return 1
      fi

      local flake_name=""

      if [ -z "$flake_name" ]; then
        flake_name="$NIXOS_DEVICE_TYPE"
      fi

      if [ -z "$flake_name" ]; then
        local available_configs
        available_configs=$(nix eval --impure --raw .#nixosConfigurations --apply 'configs: builtins.concatStringsSep "\n" (builtins.attrNames configs)' 2>/dev/null)

        if [ -n "$available_configs" ]; then
          flake_name=$(echo "$available_configs" | gum choose --header "Select NixOS configuration:")
        else
          flake_name=$(gum choose "desktop" "laptop" --header "Select NixOS configuration:")
        fi
      fi

      if [ -z "$flake_name" ]; then
        gum log --structured --level error "Specify flake name" example "nixos-apply desktop"
        return 1
      fi

      gum log --level info "Updating package count..."
      
      local sys_json=$(nix eval --json --impure ".#nixosConfigurations.$flake_name.config.environment.systemPackages" --apply 'pkgs: map (p: { name = p.pname or p.name or "unknown"; }) pkgs' 2>/dev/null || echo "[]")
      local home_json=$(nix eval --json --impure ".#nixosConfigurations.$flake_name.config.home-manager.users.$USER.home.packages" --apply 'pkgs: map (p: { name = p.pname or p.name or "unknown"; }) pkgs' 2>/dev/null || echo "[]")

      local total_packages=$(jq -r -s 'add | unique_by(.name) | map(select(.name != "unknown")) | length' <(echo "$sys_json") <(echo "$home_json") 2>/dev/null || echo 0)
      
      echo $total_packages > ~/.local/share/nix-installed-packages
      gum log --level info "Found $total_packages unique installed packages"

      echo ""

      gum log --level info "Preparing rebuild..."

      if ! sudo -n true 2>/dev/null; then
        if ! sudo -v; then
          return 1
        fi
      fi

      local outfile=$(mktemp)

      if gum spin --spinner dot --title "Building NixOS ($flake_name)..." -- \
        bash -c "set -o pipefail; sudo nixos-rebuild switch --flake '.#$flake_name' --impure 2>&1 | tee '$outfile'"; then

        read -t 0.1 -n 10000 key 2>/dev/null || true

        gum log --level info "✓ Build completed successfully!"
        rm -f "$outfile"
        return 0
      else
        read -t 0.1 -n 10000 key 2>/dev/null || true

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
          local logfile="/tmp/nixos-apply-last-error.log"
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
  '';

  nixosCleanCommand = ''
    nixos-clean() {
      sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5 && sudo nix-collect-garbage -d
    }
  '';

  nixosTestCommand = ''
    nix-test() {
      if [ $# -eq 0 ]; then
        gum log --structured --level error "No package specified," example "nix-test cowsay lolcat"
        return 1
      fi

      if ! command -v nix >/dev/null 2>&1; then
        gum log --level error "The nix command is not available on this system"
        return 2
      fi

      local packages=()
      local invalid=()
      local pkg

      for pkg in "$@"; do
        if [[ "$pkg" == -* ]]; then
          gum log --structured --level error "Unsupported option," option "$pkg"
          return 1
        fi

        if nix eval --raw "nixpkgs#$pkg.name" >/dev/null 2>&1; then
          packages+=("nixpkgs#$pkg")
        else
          invalid+=("$pkg")
        fi
      done

      if [ ''${#invalid[@]} -gt 0 ]; then
        gum log --structured --level error "Packages not found in nixpkgs," packages "''${invalid[*]}"
        return 3
      fi

      gum log --structured --level info "Starting temporary shell," packages "$*"

      NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nix shell --impure "''${packages[@]}"
      local exit_code=$?

      if [ $exit_code -ne 0 ]; then
        gum log --structured --level error "Temporary shell exited with an error," code "$exit_code"
        return $exit_code
      fi

      gum log --level info "Temporary shell closed, the packages are no longer available"
      return 0
    }
  '';
in
{
  home.packages = [
    customGum
  ];

  programs.zsh = {
    enable = true;
    
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      n = "nvim";
    };

    initContent = ''
      PROMPT_EOL_MARK=

      export NIXOS_DEVICE_TYPE="${hostType}"
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
      export EDITOR="nvim"

      # Binding for Ctrl + Arrow keys
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word

      ${compileCommand}
      ${nixosSwitchCommand}
      ${nixosCleanCommand}
      ${nixosTestCommand}

      # Oh My Posh
      eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/theme.omp.json)"

      # Fastfetch
      if command -v fastfetch >/dev/null; then
        fastfetch -c ~/.config/fastfetch/config.jsonc
      fi
    '';
  };
}
