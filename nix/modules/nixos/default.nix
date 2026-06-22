{ ... }:
{
  imports = [
    ../common
    ./boot.nix
    ./docker.nix
    ./locale.nix
    ./networking.nix
    ./tailscale.nix
    ./users.nix
  ];
}
