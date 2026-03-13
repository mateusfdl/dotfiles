{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:adisbladis/zephyr-nix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: check if Handy already updated their flake file deps hash
    handy.url = "github:cjpais/Handy/15fbc47f5a8d1127826a9d3a930336d059f6bf0f";
  };

  outputs =
    {
      nixpkgs,
      zephyr-nix,
      nix-vscode-extensions,
      claude-desktop,
      handy,
      ...
    }:
    let
      system = "x86_64-linux";
      zephyr = zephyr-nix.packages.${system};
      handy-pkg = handy.packages.${system}.default;
      claude-desktop-pkg = claude-desktop.packages.${system}.claude-desktop;
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
            claude-desktop-pkg
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
