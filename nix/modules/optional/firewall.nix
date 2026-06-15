{ config, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [
      config.services.tailscale.port
    ];
    trustedInterfaces = [
      "tailscale0"
    ];
  };
}
