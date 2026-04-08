{ pkgs, ... }:
let
  soundcloudBin = pkgs.writeShellScriptBin "soundcloud" ''
    exec ${pkgs.brave}/bin/brave --app=https://soundcloud.com "$@"
  '';

  soundcloudDesktop = pkgs.makeDesktopItem {
    name = "soundcloud";
    desktopName = "SoundCloud";
    comment = "SoundCloud Music Streaming";
    icon = "soundcloud";
    exec = "soundcloud";
    categories = [ "AudioVideo" "Audio" ];
    startupNotify = true;
    startupWMClass = "soundcloud.com";
  };
in
{
  environment.systemPackages = [ soundcloudBin soundcloudDesktop ];
}
