{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/common
    ../../modules/optional/firewall.nix
    ../../modules/optional/k3s.nix
    ../../modules/optional/argocd.nix
    ../../modules/optional/maintenance.nix
    ../../modules/optional/openssh.nix
    ../../modules/optional/alloy.nix
    ../../pkgs/server.nix
  ];

  networking.hostName = "beelink-n1";

  virtualisation.docker.autoPrune.enable = true;
  users.users.matheus.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOKp5xAxoqTYtxvBcT6W+FMkVb0Bd7qE9Xk2IbHIRFh"
  ];

  system.stateVersion = "25.11";
}
