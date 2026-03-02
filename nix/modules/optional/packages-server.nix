{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    docker-compose
    git
    htop
    iotop
    jq
    lsof
    tmux
    tree
    unzip
    vim
    wget
  ];
}
