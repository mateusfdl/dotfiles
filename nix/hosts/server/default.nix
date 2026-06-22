{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/optional/firewall.nix
    ../../modules/nixos/optional/k3s.nix
    ../../modules/nixos/optional/argocd.nix
    ../../modules/nixos/optional/maintenance.nix
    ../../modules/nixos/optional/openssh.nix
    ../../modules/nixos/optional/alloy.nix
    ../../modules/nixos/optional/conntrack-exporter.nix
    ../../pkgs/server.nix
  ];

  networking.hostName = "beelink-n1";

  services.tailscale.extraDaemonFlags = [
    "--debug=localhost:41112"
  ];

  virtualisation.docker.autoPrune.enable = true;
  users.users.matheus.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOKp5xAxoqTYtxvBcT6W+FMkVb0Bd7qE9Xk2IbHIRFh"
  ];

  system.stateVersion = "25.11";
}
