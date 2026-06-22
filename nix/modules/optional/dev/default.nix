{ pkgs, ... }:
{
  imports = [
    ./ruby.nix
    ./python.nix
    ./mise.nix
    ./jq.nix
    ./yq.nix
    ./entr.nix
    ./pandoc.nix
    ./tectonic.nix
    ./graphviz.nix
    ./flyctl.nix
    ./railway.nix
    ./revdiff.nix
    ./lazydocker.nix
    ./claude-code.nix
    ./opencode.nix
    ./cmakelint.nix
    ./ripgrep.nix
    ./eza.nix
    ./tokei.nix
    ./stylua.nix
    ./hyperfine.nix
    ./fd.nix
    ./sd.nix
    ./fzf.nix
    ./neovim.nix
    ./bubblewrap.nix
    ./zephyr.nix
    ./kata.nix
  ];

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
  ];
}
