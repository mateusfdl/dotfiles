{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.graphviz ];
}
