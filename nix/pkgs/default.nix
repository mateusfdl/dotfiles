pkgs: {
  ankama-launcher = pkgs.callPackage ./ankama-launcher/package.nix { };
  cmakelint = pkgs.callPackage ./cmakelint/package.nix { };
  paseo-desktop = pkgs.callPackage ./paseo-desktop/package.nix { };
  pop = pkgs.callPackage ./pop/package.nix { };
  raddebugger = pkgs.callPackage ./raddebugger/package.nix { };
  sf-pro-fonts = pkgs.callPackage ./sf-pro-fonts/package.nix { };
}
