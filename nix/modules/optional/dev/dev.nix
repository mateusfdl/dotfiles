{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        pip
        virtualenv
        requests
      ]
    ))

    gcc
    clang-tools
    gnumake
    openssl.dev
    pkg-config
    mise
    jq
  ];
}
