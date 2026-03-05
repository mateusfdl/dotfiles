{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:adisbladis/zephyr-nix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # TODO: check if Handy already updated their flake file deps hash
    handy.url = "github:cjpais/Handy/15fbc47f5a8d1127826a9d3a930336d059f6bf0f";
  };

  outputs =
    {
      nixpkgs,
      zephyr-nix,
      nix-vscode-extensions,
      handy,
      ...
    }:
    let
      system = "x86_64-linux";
      zephyr = zephyr-nix.packages.${system};
      handy-pkg = handy.packages.${system}.default;
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
        specialArgs = {
          inherit
            zephyr
            vscode-marketplace
            vscode-marketplace-universal
            handy-pkg
            ;
        };
        modules = [ ./hosts/desktop ];
      };

      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/server ];
      };
    };
}
