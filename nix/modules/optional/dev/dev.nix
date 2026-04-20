{ pkgs, ... }:
{
  environment.sessionVariables = {
    LIBRARY_PATH = "${pkgs.zlib}/lib";
  };

  environment.systemPackages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        pip
        virtualenv
        requests
      ]
    ))
    uv

    ruby
    gcc
    clang-tools
    gnumake
    openssl.dev
    pkg-config
    webkitgtk_4_1
    webkitgtk_4_1.dev
    libsoup_3.dev

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly

    mise
    jq
    entr
    pandoc
    tectonic
  ];

  environment.sessionVariables.GST_PLUGIN_PATH = pkgs.lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-plugins-ugly
  ];
}
