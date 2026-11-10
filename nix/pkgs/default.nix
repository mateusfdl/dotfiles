pkgs: {
  paseo-desktop = pkgs.callPackage ./paseo-desktop/package.nix { };
  pop = pkgs.callPackage ./pop/package.nix { };
}
