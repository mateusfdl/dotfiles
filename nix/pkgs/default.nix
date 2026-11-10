pkgs: {
  paseo-desktop = pkgs.callPackage ./paseo-desktop/package.nix { };
  pop = pkgs.callPackage ./pop/package.nix { };
  raddebugger = pkgs.callPackage ./raddebugger/package.nix { };
}
