{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
}
