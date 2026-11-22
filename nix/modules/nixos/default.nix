{ ... }:
{
  imports = [
    ../common
    ./boot.nix
    ./docker.nix
    ./firewall.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./tailscale.nix
    ./users.nix
  ];
}
