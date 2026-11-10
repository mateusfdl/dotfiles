{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  system = stdenvNoCC.hostPlatform.system;

  sources = {
    x86_64-linux = {
      asset = "linux-amd64";
      hash = "sha256-YZNVXAH+/jEtUVGI/Ul5wx3E6aXpQGxhT/1uz33rzAA=";
    };
    aarch64-darwin = {
      asset = "darwin-arm64";
      hash = "sha256-EMQGn4Zi2VvIGig3kUW4lgH+z5sO8ti5IZmi0NiSqCs=";
    };
  };

  source = sources.${system} or (throw "vikunja-cli: no release asset for ${system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vikunja-cli";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/jo-nike/vikunja-cli/releases/download/v${finalAttrs.version}/vikunja-cli-${source.asset}.tar.gz";
    inherit (source) hash;
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
    license = lib.licenses.mit;
    mainProgram = "vikunja-cli";
    platforms = builtins.attrNames sources;
  };
})
