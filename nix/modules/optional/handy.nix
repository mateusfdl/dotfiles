{ pkgs, inputs, system, ... }:
{
  environment.systemPackages = [
    inputs.handy.packages.${system}.default
    pkgs.wtype
  ];
}
