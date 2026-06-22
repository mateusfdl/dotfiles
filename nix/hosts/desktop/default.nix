{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/optional/audio.nix
    ../../modules/nixos/optional/blender.nix
    ../../modules/nixos/optional/bluetooth.nix
    ../../modules/nixos/optional/brave.nix
    ../../modules/nixos/optional/desktop-reliability.nix
    ../../modules/nixos/optional/firewall.nix
    ../../modules/nixos/optional/fonts.nix
    ../../modules/nixos/optional/greetd.nix
    ../../modules/nixos/optional/handy.nix
    ../../modules/nixos/optional/hyprland.nix
    ../../modules/nixos/optional/nautilus.nix
    ../../modules/nixos/optional/nvidia.nix
    ../../modules/nixos/optional/nix-ld.nix
    ../../modules/nixos/optional/obs.nix
    ../../modules/nixos/optional/pop.nix
    ../../modules/nixos/optional/portals.nix
    ../../modules/nixos/optional/sshfs.nix
    ../../modules/nixos/optional/steam.nix
    ../../modules/nixos/optional/vscode.nix
    ../../modules/nixos/optional/soundcloud.nix
    ../../modules/nixos/optional/dev.nix
    ../../modules/nixos/optional/zephyr.nix

    ../../pkgs/desktop.nix
  ];

  networking.hostName = "desktop";

  home-manager.users.matheus = import ../../home/matheus;

  programs.ssh.startAgent = true;

  services.tailscale.extraSetFlags = [
    "--ssh"
  ];

  users.users.matheus.extraGroups = [
    "video"
    "audio"
  ];

  system.stateVersion = "25.11";
}
