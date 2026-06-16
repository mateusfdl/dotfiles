{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libcap
    libcap.dev
    libselinux
    libselinux.dev
    meson
    ninja
    pcre2.dev
  ];
}
