{ username, ... }:
{
  imports = [
    ../../modules/darwin
  ];

  networking.hostName = "macbook";

  home-manager.users.${username} = import ../../home/matheus;

  system.stateVersion = 7;
}
