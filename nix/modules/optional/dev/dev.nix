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

    gcc
    clang-tools
    gnumake
    openssl.dev
    pkg-config
    webkitgtk_4_1
    webkitgtk_4_1.dev
    libsoup_3.dev
    mise
    jq
  ];
}
