{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:adisbladis/zephyr-nix";
  };

  outputs = { self, nixpkgs, zephyr-nix, ... }:
    let
      system = "x86_64-linux";
      zephyr = zephyr-nix.packages.${system};
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit zephyr; };
        modules = [ ./hosts/desktop ];
      };
    };
}
