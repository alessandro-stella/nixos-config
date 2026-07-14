{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config = {
      url = "github:alessandro-stella/OrionVim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nvim-config, ...}:
  {
    nixosConfigurations = {
      desktop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
	    { nixpkgs.config.allowUnfree = true; }

            ./hosts/desktop/configuration.nix
            ./modules/common/packages.nix
            ./modules/common/hyprland.nix
            ./modules/machines/desktop.nix

            home-manager.nixosModules.home-manager

            {
              home-manager.users.ale-nix = import ./home/ale-nix/home.nix;

              home-manager.extraSpecialArgs = {
                inherit nvim-config;
              };
            }
          ];
        };

    laptop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
	    { nixpkgs.config.allowUnfree = true; }

            ./hosts/laptop/configuration.nix
            ./modules/common/packages.nix
            ./modules/common/hyprland.nix
            ./modules/machines/laptop.nix

            home-manager.nixosModules.home-manager

            {
              home-manager.users.ale-nix = import ./home/ale-nix/home.nix;

              home-manager.extraSpecialArgs = {
                inherit nvim-config;
              };
            }
          ];
        };
    };
  };
}
