{ config, pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";

    extraFlags = toString [
      "--disable=traefik"
      "--write-kubeconfig-mode=0644"
      "--tls-san=${config.networking.hostName}"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [ 6443 10250 ];
    allowedUDPPorts = [ 8472 ];
    trustedInterfaces = [ "cni0" "flannel.1" ];
  };

  boot.kernelModules = [
    "br_netfilter"
    "overlay"
    "ip_tables"
    "iptable_nat"
    "iptable_filter"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward"                 = 1;
    "net.ipv6.conf.all.forwarding"        = 1;
    "net.bridge.bridge-nf-call-iptables"  = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };

  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];

  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
}
