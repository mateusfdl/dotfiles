{ pkgs, ... }:
{
  programs.ydotool.enable = true;

  users.users.matheus.extraGroups = [ "ydotool" ];

  environment.systemPackages = with pkgs; [
    jq
    socat
    wlrctl
    wtype
  ];
}
