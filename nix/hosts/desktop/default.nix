{ ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos
    ../../modules/nixos/hardware/audio.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/desktop/brave.nix
    ../../modules/nixos/desktop/reliability.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/greetd.nix
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/desktop/nautilus.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/dev/nix-ld.nix
    ../../modules/nixos/obs/obs.nix
    ../../modules/nixos/agent/paseo.nix
    ../../modules/nixos/desktop/portals.nix
    ../../modules/nixos/dev/raddebugger.nix
    ../../modules/nixos/ssh/sshfs.nix
    ../../modules/nixos/games/steam.nix
    ../../modules/nixos/dev/vscode.nix
    ../../modules/nixos/desktop/soundcloud.nix
    ../../modules/nixos/dev/toolchain.nix
    ../../modules/nixos/dev/zephyr.nix
    ../../modules/nixos/games/dofus.nix
    ./packages.nix
  ];

  networking.hostName = "desktop";

  home-manager.users.matheus.imports = [
    ../../home/matheus
    ../../home/matheus/linux.nix
  ];

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
