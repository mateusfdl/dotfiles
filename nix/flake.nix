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
      vscode-marketplace = nix-vscode-extensions.extensions.${system}.vscode-marketplace;
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit zephyr vscode-marketplace; };
        modules = [ ./hosts/desktop ];
      };

      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/server ];
      };
    };
}
