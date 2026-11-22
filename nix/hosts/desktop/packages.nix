{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bubblewrap
    ghostty
    glib
    nftables
    unzip
    vim
    wget
    wireguard-tools
  ];
}
