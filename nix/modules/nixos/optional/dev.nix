{ pkgs, ... }:
{
  environment.sessionVariables = {
    LIBRARY_PATH = "${pkgs.zlib}/lib";
    GST_PLUGIN_PATH = pkgs.lib.makeSearchPath "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-plugins-ugly
    ];
  };

  environment.systemPackages = with pkgs; [
    gcc
    clang-tools
    gnumake
    meson
    ninja
    pkg-config

    openssl.dev
    libcap
    libcap.dev
    libselinux
    libselinux.dev
    pcre2.dev

    webkitgtk_4_1
    webkitgtk_4_1.dev
    libsoup_3.dev

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];
}
