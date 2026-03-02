{ config, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
    ];
    allowedUDPPorts = [
      config.services.tailscale.port
    ];
    trustedInterfaces = [
      "tailscale0"
    ];
  };
}
