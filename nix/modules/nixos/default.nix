{ ... }:
{
  imports = [
    ../common
    ./boot.nix
    ./docker.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./tailscale.nix
    ./users.nix
  ];
}
