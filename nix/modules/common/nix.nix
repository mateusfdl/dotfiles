{ ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (final: prev: import ../../pkgs final) ];

  nix.settings = {
    auto-optimise-store = true;
    cores = 0;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    keep-derivations = true;
    keep-outputs = true;
    max-jobs = "auto";
    trusted-users = [
      "root"
      "matheus"
    ];
    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}
