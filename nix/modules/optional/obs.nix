{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        obs-shaderfilter
      ];
    })
  ];
}
