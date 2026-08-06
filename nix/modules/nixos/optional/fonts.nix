{ pkgs, ... }:
let
  sf-pro = pkgs.stdenvNoCC.mkDerivation {
    pname = "sf-pro-fonts";
    version = "8bfea09";
    src = pkgs.fetchFromGitHub {
      owner = "sahibjotsaggu";
      repo = "San-Francisco-Pro-Fonts";
      rev = "8bfea09aa6f1139479f80358b2e1e5c6dc991a58";
      hash = "sha256-mAXExj8n8gFHq19HfGy4UOJYKVGPYgarGd/04kUIqX4=";
    };
    installPhase = ''
      runHook preInstall
      install -Dm444 -t $out/share/fonts/opentype/sf-pro *.otf
      install -Dm444 -t $out/share/fonts/truetype/sf-pro *.ttf
      runHook postInstall
    '';
  };
in
{
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    open-sans
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.monaspace
    material-icons
    material-symbols
    sf-pro
  ];
}
