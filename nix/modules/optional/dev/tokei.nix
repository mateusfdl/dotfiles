{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.tokei ];
}
