{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.pandoc ];
}
