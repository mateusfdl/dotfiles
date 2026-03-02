{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    # common modules (shared by all hosts)
    ../../modules/common

    # optional modules (server-specific)
    ../../modules/optional/firewall.nix
    ../../modules/optional/maintenance.nix
    ../../modules/optional/openssh.nix
    ../../modules/optional/packages-server.nix
  ];

  networking.hostName = "beelink-n1";

  # docker auto-prune for server (weekly cleanup of unused images)
  virtualisation.docker.autoPrune.enable = true;

  # server user: SSH key auth from desktop
  users.users.matheus.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOKp5xAxoqTYtxvBcT6W+FMkVb0Bd7qE9Xk2IbHIRFh matheus@desktop"
  ];

  system.stateVersion = "25.11";
}
