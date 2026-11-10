{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.pop ];
}
