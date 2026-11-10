{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    docker-compose
    git
    htop
    iproute2
    iotop
    jq
    kubeconform
    kustomize
    lsof
    skopeo
    tmux
    tree
    unzip
    vim
    wget
    yamllint
    yq-go
  ];
}
