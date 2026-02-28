{ pkgs, ... }:
{
  users.users.matheus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      spotify
      obsidian
      discord
    ];
  };
}
