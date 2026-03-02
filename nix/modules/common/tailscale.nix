{ ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--operator=matheus"
      "--accept-routes"
    ];
  };
}
