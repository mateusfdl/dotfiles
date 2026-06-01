{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.flyctl ];
}
