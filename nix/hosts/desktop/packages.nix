{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bubblewrap
    glib
    kitty
    nftables
    unzip
    vim
    wget
    wireguard-tools
  ];
}
