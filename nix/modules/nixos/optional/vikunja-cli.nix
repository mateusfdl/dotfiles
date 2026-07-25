{ pkgs, ... }:
let
  vikunja-cli = pkgs.stdenvNoCC.mkDerivation {
    pname = "vikunja-cli";
    version = "1.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/jo-nike/vikunja-cli/releases/download/v1.0.0/vikunja-cli-linux-amd64.tar.gz";
      hash = "sha256-YZNVXAH+/jEtUVGI/Ul5wx3E6aXpQGxhT/1uz33rzAA=";
    };

    sourceRoot = ".";
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 vikunja-cli "$out/bin/vikunja-cli"
      runHook postInstall
    '';

    meta = {
      description = "Command-line client for Vikunja";
      homepage = "https://github.com/jo-nike/vikunja-cli";
      license = pkgs.lib.licenses.mit;
      mainProgram = "vikunja-cli";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [ vikunja-cli ];
}
