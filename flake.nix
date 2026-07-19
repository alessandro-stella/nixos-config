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

  outputs = { self, nixpkgs, home-manager, nvim-config, ...}@inputs:
  let
    sharedModules = [
      { 
        nixpkgs.config.allowUnfree = true;
        services.openssh.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 ];
      }

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit nvim-config; };
        home-manager.users."ale-nix" = import ./home/ale-nix/home.nix;
      }
    ];
  in
  {
    nixosConfigurations = {
      desktop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/desktop/configuration.nix ] ++ sharedModules;
        };

      laptop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [ ./hosts/laptop/configuration.nix ] ++ sharedModules;
        };
    };
  };
}
