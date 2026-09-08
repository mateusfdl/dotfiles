{ pkgs, ... }:
let
  obs-shaderfilter = pkgs.obs-studio-plugins.obs-shaderfilter.overrideAttrs {
    version = "2.6.0-unstable-2026-05-21";
    src = pkgs.fetchFromGitHub {
      owner = "exeldro";
      repo = "obs-shaderfilter";
      rev = "851c61eb4e293704360068d7bb8c93a251bb5718";
      hash = "sha256-owQ8bQriyLrq4ekNUy7TPS3jnOzCXBNex5M5EHk2K6M=";
    };
  };
in
{
  environment.systemPackages = [
    (pkgs.wrapOBS { plugins = [ obs-shaderfilter ]; })
  ];
}
