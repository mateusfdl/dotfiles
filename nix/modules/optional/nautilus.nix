{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nautilus
    nautilus-python
    ffmpegthumbnailer
    totem
    libheif
  ];

  services.gvfs.enable = true;
  services.devmon.enable = true;

  environment.etc."xdg/thumbnailers/ffmpegthumbnailer.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=ffmpegthumbnailer
    Exec=ffmpegthumbnailer -i %i -o %o -s %s -f
    MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-flv;video/x-matroska;video/webm;video/x-mpeg;video/x-mp4;video/x-avi;
  '';

  environment.etc."xdg/thumbnailers/totem.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=totem-video-thumbnailer
    Exec=totem-video-thumbnailer -s %s %i %o
    MimeType=video/3gp;video/3gpp;video/asf;video/avi;video/divx;video/dv;video/fli;video/flv;video/mp2t;video/mp4;video/mp4v-es;video/mpeg;video/msvideo;video/ogg;video/quicktime;video/vivo;video/vnd.divx;video/vnd.avi;video/vnd.rn-realvideo;video/vnd.vivo;video/webm;video/x-anim;video/x-avi;video/x-flc;video/x-fli;video/x-fll;video/x-flv;video/x-m4v;video/x-matroska;video/x-mpeg;video/x-mpeg2;video/x-ms-asf;video/x-ms-asf-plugin;video/x-ms-wmv;video/x-msvideo;video/x-ogm+ogg;video/x-theora;video/x-theora+ogg;
  '';

  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/nautilus/preferences" = {
        show-image-thumbnails = "always";
        thumbnail-limit = 104857600;
        show-thumbnails = true;
      };
      "org/gnome/desktop/thumbnailers" = {
        disable-all = false;
        disable = [];
      };
      "org/gnome/nautilus/list-view" = {
        use-tree-view = false;
      };
    };
  }];

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    THUMBNAIL_CACHE_DIRECTORY = "$HOME/.cache/thumbnails";
  };
}
