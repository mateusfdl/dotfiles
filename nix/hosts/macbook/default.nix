{ ... }:
{
  imports = [
    ../../modules/darwin
  ];

  networking.hostName = "macbook";

  home-manager.users.matheus = import ../../home/matheus;

  system.stateVersion = 5;
}
