{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/k8s/k3s.nix
    ../../modules/nixos/k8s/argocd.nix
    ./maintenance.nix
    ../../modules/nixos/ssh/openssh.nix
    ../../modules/nixos/monitoring/alloy.nix
    ../../modules/nixos/monitoring/conntrack-exporter.nix
    ./packages.nix
  ];

  networking.hostName = "beelink-n1";

  virtualisation.docker.autoPrune.enable = true;
  users.users.matheus.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOKp5xAxoqTYtxvBcT6W+FMkVb0Bd7qE9Xk2IbHIRFh"
  ];

  system.stateVersion = "25.11";
}
