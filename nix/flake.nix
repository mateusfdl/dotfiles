{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:adisbladis/zephyr-nix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    {
      self,
      nixpkgs,
      zephyr-nix,
      nix-vscode-extensions,
      ...
    }:
    let
      system = "x86_64-linux";
      zephyr = zephyr-nix.packages.${system};
      pkgsWithVscodeExts = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nix-vscode-extensions.overlays.default ];
      };
      vscode-marketplace = pkgsWithVscodeExts.nix-vscode-extensions.vscode-marketplace;
      vscode-marketplace-universal =
        pkgsWithVscodeExts.nix-vscode-extensions.vscode-marketplace-universal;
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit zephyr vscode-marketplace vscode-marketplace-universal; };
        modules = [ ./hosts/desktop ];
      };

      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/server ];
      };
    };
}
