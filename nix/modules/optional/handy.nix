{ pkgs, handy-pkg, ... }:
{
  environment.systemPackages = [
    handy-pkg
    pkgs.wtype
  ];
}
