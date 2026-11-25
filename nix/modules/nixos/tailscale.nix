{ username, ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--operator=${username}"
      "--accept-routes"
    ];
  };
}
