{ ... }:
{
  imports = [
    ./boot.nix
    ./docker.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./shell.nix
    ./tailscale.nix
    ./users.nix
  ];
}
