{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.yq ];
}
