{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.xdg-desktop-portal-hyprland ];
    config = {
      Hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  xdg.mime.defaultApplications = {
    "video/mp4" = "vlc.desktop";
    "video/mkv" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/webm" = "vlc.desktop";
    "video/avi" = "vlc.desktop";
    "video/x-msvideo" = "vlc.desktop";
    "video/ogg" = "vlc.desktop";
    "video/quicktime" = "vlc.desktop";
    "video/x-flv" = "vlc.desktop";
    "video/mpeg" = "vlc.desktop";
  };

  programs.dconf.enable = true;
}
