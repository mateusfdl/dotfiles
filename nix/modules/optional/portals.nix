{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  xdg.mime.defaultApplications = {
    "video/mp4" = "mpv.desktop";
    "video/mkv" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/avi" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/ogg" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-flv" = "mpv.desktop";
    "video/mpeg" = "mpv.desktop";
  };

  programs.dconf.enable = true;
}
