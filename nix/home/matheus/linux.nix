{ pkgs, inputs, ... }:
let
  claude-desktop = inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
in
{
  home.packages = with pkgs; [
    claude-desktop
    discord
    morgen
    mpv
    obsidian
    spotify
  ];
}
