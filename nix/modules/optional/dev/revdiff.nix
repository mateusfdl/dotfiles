{ pkgs, ... }:
let
  revdiff = pkgs.buildGoModule rec {
    pname = "revdiff";
    version = "unstable-2026-05-24";

    src = pkgs.fetchFromGitHub {
      owner = "umputun";
      repo = "revdiff";
      rev = "a80e92d998448c50e18a67bebda05f41939fd561";
      hash = "sha256-M9dYe7VuUGa+6qYIMXXgQfCyUr/ZahBcxDU1tQogY9Y=";
    };

    vendorHash = null;

    subPackages = [ "app" ];

    doCheck = false;

    postInstall = ''
      mv $out/bin/app $out/bin/revdiff
    '';

    meta = {
      description = "TUI for reviewing diffs, files, and documents with inline annotations";
      homepage = "https://github.com/umputun/revdiff";
      license = pkgs.lib.licenses.mit;
      mainProgram = "revdiff";
      platforms = pkgs.lib.platforms.unix;
    };
  };
in
{
  environment.systemPackages = [ revdiff ];
}
