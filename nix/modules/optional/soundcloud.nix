{ pkgs, ... }:
let
  soundcloud = pkgs.makeDesktopItem {
    name = "soundcloud";
    desktopName = "SoundCloud";
    comment = "SoundCloud Music Streaming";
    icon = "soundcloud";
    exec = "${pkgs.brave}/bin/brave --app=https://soundcloud.com";
    categories = [ "AudioVideo" "Audio" ];
    startupNotify = true;
    startupWMClass = "soundcloud.com";
  };
in
{
  environment.systemPackages = [ soundcloud ];
}
