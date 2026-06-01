{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.claude-code ];
}
