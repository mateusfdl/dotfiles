{ pkgs, inputs, ... }:
let
  zig = pkgs.zig;
  kata = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "kata";
    version = "1.0.0";
    src = inputs.kata;

    zigDeps = zig.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-CgyvBABSygnMmKFeUCNM9FFPkdBNNWWJ6Hxs55ozdUw=";
    };

    nativeBuildInputs = [ zig.hook ];

    dontSetZigDefaultFlags = true;

    postConfigure = ''
      ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    zigBuildFlags = [
      "-Doptimize=ReleaseFast"
      "-Dstrip=true"
    ];

    meta = {
      description = "Tree-sitter-based linter for coding-style rules";
      homepage = "https://github.com/mateusfdl/kata";
      license = pkgs.lib.licenses.mit;
      mainProgram = "kata";
      platforms = pkgs.lib.platforms.unix;
    };
  });
in
{
  environment.systemPackages = [ kata ];
}
