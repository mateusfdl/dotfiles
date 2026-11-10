{
  description = "Multi-host, multi-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zephyr-nix.url = "github:adisbladis/zephyr-nix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

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
      homeManagerSettings = system: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs system; };
      };

      mkNixos =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = modules ++ [
            inputs.home-manager.nixosModules.home-manager
            (homeManagerSettings system)
          ];
        };

      mkDarwin =
        system: modules:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = modules ++ [
            inputs.home-manager.darwinModules.home-manager
            (homeManagerSettings system)
          ];
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;

      nixosConfigurations = {
        desktop = mkNixos "x86_64-linux" [ ./hosts/desktop ];
        server = mkNixos "x86_64-linux" [ ./hosts/server ];
      };

      darwinConfigurations = {
        macbook = mkDarwin "aarch64-darwin" [ ./hosts/macbook ];
      };
    };
}
