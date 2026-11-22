{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    nautilus
    nautilus-python
    ffmpegthumbnailer
    libheif
    vlc
    loupe
  ];

  services.gvfs.enable = true;
  services.devmon.enable = true;

  environment.etc."xdg/thumbnailers/ffmpegthumbnailer.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=ffmpegthumbnailer
    Exec=ffmpegthumbnailer -i %i -o %o -s %s -f
    MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-flv;video/x-matroska;video/webm;video/x-mpeg;video/x-mp4;video/x-avi;video/3gp;video/3gpp;video/asf;video/avi;video/divx;video/dv;video/fli;video/flv;video/mp2t;video/mp4v-es;video/msvideo;video/ogg;video/vivo;video/vnd.divx;video/vnd.avi;video/vnd.rn-realvideo;video/vnd.vivo;video/x-anim;video/x-flc;video/x-fli;video/x-fll;video/x-m4v;video/x-mpeg2;video/x-ms-asf-plugin;video/x-ogm+ogg;video/x-theora;video/x-theora+ogg;
  '';

  environment.etc."xdg/gtk-3.0/gtk.css".text = ''
    .nautilus-canvas-item {
      border: none;
      box-shadow: none;
    }

    .nautilus-canvas-item.thumbnail,
    .nautilus-canvas-item.thumbnail::before,
    .nautilus-canvas-item.thumbnail::after {
      border: none;
      box-shadow: none;
    }

    NautilusCanvasItem {
      border: none;
    }

    .thumbnail {
      border: none;
      outline: none;
    }

    NautilusIconContainer {
      border: none;
    }
  '';

  environment.etc."xdg/gtk-4.0/gtk.css".text = ''
    .nautilus-canvas-item {
      border: none;
      box-shadow: none;
    }

    .nautilus-canvas-item.thumbnail,
    .nautilus-canvas-item.thumbnail::before,
    .nautilus-canvas-item.thumbnail::after {
      border: none;
      box-shadow: none;
    }

    NautilusCanvasItem {
      border: none;
    }

    .thumbnail {
      border: none;
      outline: none;
    }

    NautilusIconContainer {
      border: none;
    }
  '';

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/nautilus/preferences" = {
          show-image-thumbnails = "always";
          thumbnail-limit = lib.gvariant.mkUint64 104857600;
          show-thumbnails = true;
        };
        "org/gnome/desktop/thumbnailers" = {
          disable-all = false;
          disable = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
        };
        "org/gnome/nautilus/list-view" = {
          use-tree-view = false;
        };
      };
    }
  ];

  xdg.mime.defaultApplications = {
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/png" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "image/x-icon" = "org.gnome.Loupe.desktop";
    "image/heic" = "org.gnome.Loupe.desktop";
    "image/heif" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
    "image/raw" = "org.gnome.Loupe.desktop";
    "image/x-canon-cr2" = "org.gnome.Loupe.desktop";
    "image/x-nikon-nef" = "org.gnome.Loupe.desktop";
    "image/x-sony-arw" = "org.gnome.Loupe.desktop";
  };

}
