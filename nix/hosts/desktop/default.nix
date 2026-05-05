{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/optional/audio.nix
    ../../modules/optional/blender.nix
    ../../modules/optional/bluetooth.nix
    ../../modules/optional/fonts.nix
    ../../modules/optional/greetd.nix
    ../../modules/optional/handy.nix
    ../../modules/optional/hyprland.nix
    ../../modules/optional/nautilus.nix
    ../../modules/optional/nvidia.nix
    ../../modules/optional/nix-ld.nix
    ../../modules/optional/obs.nix
    ../../modules/optional/pop.nix
    ../../pkgs/desktop.nix
    ../../modules/optional/portals.nix
    ../../modules/optional/sshfs.nix
    ../../modules/optional/steam.nix
    ../../modules/optional/vscode.nix
    ../../modules/optional/soundcloud.nix
    ../../modules/optional/dev
  ];

  networking.hostName = "desktop";

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
