{ ... }:
{
  imports = [
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/nix-ld.nix
    ./modules/audio.nix
    ./modules/docker.nix
    ./modules/users.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
    ./modules/greetd.nix
    ./modules/portals.nix
    ./modules/nvidia.nix
    ./modules/fonts.nix
    ./modules/packages.nix
    ./modules/dev
    ./modules/bluetooth.nix
    ./modules/steam.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
