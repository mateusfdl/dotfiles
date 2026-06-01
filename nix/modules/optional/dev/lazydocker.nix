{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lazydocker ];
}
