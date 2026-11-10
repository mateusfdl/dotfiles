{
  description = "Multi-host, multi-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zephyr-nix.url = "github:adisbladis/zephyr-nix";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";

    kata = {
      url = "github:mateusfdl/kata";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      homeManagerSettings = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs; };
      };

      mkNixos =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = modules ++ [
            inputs.home-manager.nixosModules.home-manager
            homeManagerSettings
          ];
        };

      mkDarwin =
        system: modules:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = modules ++ [
            inputs.home-manager.darwinModules.home-manager
            homeManagerSettings
          ];
        };
    in
    {
      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system:
        nixpkgs.legacyPackages.${system}.nixfmt-tree.override {
          settings = {
            tree-root-file = "flake.nix";
            formatter.nixfmt.excludes = [ "home/matheus/ruby/gemset.nix" ];
          };
        }
      );

      packages.x86_64-linux = import ./pkgs (
        import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        }
      );

      nixosConfigurations = {
        desktop = mkNixos "x86_64-linux" [ ./hosts/desktop ];
        server = mkNixos "x86_64-linux" [ ./hosts/server ];
      };

      darwinConfigurations = {
        macbook = mkDarwin "aarch64-darwin" [ ./hosts/macbook ];
      };
    };
}
