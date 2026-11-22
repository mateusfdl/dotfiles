{ pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    morgen
    mpv
    obsidian
    spotify
  ];
}
