{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    # common modules (shared by all hosts)
    ../../modules/common

    # optional modules (desktop-specific)
    ../../modules/optional/audio.nix
    ../../modules/optional/bluetooth.nix
    ../../modules/optional/fonts.nix
    ../../modules/optional/greetd.nix
    ../../modules/optional/hyprland.nix
    ../../modules/optional/nvidia.nix
    ../../modules/optional/nix-ld.nix
    ../../modules/optional/packages-desktop.nix
    ../../modules/optional/portals.nix
    ../../modules/optional/sshfs.nix
    ../../modules/optional/steam.nix
    ../../modules/optional/dev
  ];

  networking.hostName = "desktop";

  users.users.matheus.extraGroups = [ "video" "audio" ];

  system.stateVersion = "25.11";
}
