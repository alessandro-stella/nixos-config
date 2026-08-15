{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    brave-origin.url = "github:Daniel-42-z/brave-origin-flake";

    minegrub-world-sel-theme = {
      url = "github:Lxtharia/minegrub-world-sel-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ...}@inputs:
  let
    username = "alessandro";
    dotfilesPath = "/home/${username}/nixos-config/home/dotfiles";

    sharedModules = [
      { 
        nixpkgs.config.allowUnfree = true;
        services.openssh.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 ];
      }
      home-manager.nixosModules.home-manager
    ];
    
    homeManagerConfig = hostType: modules: {
      home-manager.extraSpecialArgs = { inherit inputs username hostType dotfilesPath; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [ ./home/home-common.nix ] ++ modules;
      };
    };
  in
  {
    nixosConfigurations = {
      desktop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit username; };
          modules = [ 
            ./hosts/desktop/configuration.nix
            inputs.minegrub-world-sel-theme.nixosModules.default
            (homeManagerConfig "desktop" [ ./home/home-desktop.nix ])
          ] ++ sharedModules;
        };
      laptop = 
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit username; };
          modules = [ 
            ./hosts/laptop/configuration.nix
            (homeManagerConfig "laptop" [ ./home/home-laptop.nix ])
          ] ++ sharedModules;
        };
    };
  };
}
