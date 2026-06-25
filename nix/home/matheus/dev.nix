{ pkgs, inputs, ... }:
let
  zig = pkgs.zig;
  flowZig = pkgs.zig_0_15;

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

  flow = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "flow";
    version = "0.7.2";

    src = pkgs.fetchFromGitHub {
      owner = "neurocyte";
      repo = "flow";
      rev = "v${finalAttrs.version}";
      hash = "sha256-5+F0DKb4LXtcMXNutUSJuIe7cdBoFUoJhCs8vbm20jg=";
    };

    zigDeps = pkgs.runCommand "flow-${finalAttrs.version}-zig-deps" {
      inherit (finalAttrs) src;
      nativeBuildInputs = [
        flowZig
        pkgs.cacert
      ];
      outputHashAlgo = null;
      outputHashMode = "recursive";
      outputHash = "sha256-HX7NGdOmYEqlncDlxU7zGSfLawtM+SNKMFvHjTkCE+Y=";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    } ''
      export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
      runHook unpackPhase
      cd "$sourceRoot"
      zig build --fetch
      mv "$ZIG_GLOBAL_CACHE_DIR/p" "$out"
    '';

    nativeBuildInputs = [ flowZig.hook ];

    dontSetZigDefaultFlags = true;

    postConfigure = ''
      cp -r --no-preserve=mode ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    zigBuildFlags = [ "-Doptimize=ReleaseSafe" ];

    meta = {
      description = "Programmer's text editor with multi-cursor, LSP, and syntax highlighting";
      homepage = "https://github.com/neurocyte/flow";
      license = pkgs.lib.licenses.mit;
      mainProgram = "flow";
      platforms = pkgs.lib.platforms.unix;
    };
  });

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

  cmakelint = pkgs.python3Packages.buildPythonApplication rec {
    pname = "cmakelint";
    version = "1.4.3";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-mKHkhTGLQe6vTe40acowOdR0WYU1Ps6iCNbdLBIExx0=";
    };

    build-system = [ pkgs.python3Packages.setuptools ];

    pythonImportsCheck = [ "cmakelint" ];

    meta = {
      description = "Linter for CMake files";
      homepage = "https://github.com/cmake-lint/cmake-lint";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "cmakelint";
    };
  };

  lumen = pkgs.rustPlatform.buildRustPackage rec {
    pname = "lumen";
    version = "2.30.0";

    src = pkgs.fetchFromGitHub {
      owner = "jnsahaj";
      repo = "lumen";
      rev = "v${version}";
      hash = "sha256-EoxMYlWHmuprjjhvj3GyCxGDIcT/d+JMda9j75pqs+k=";
    };

    cargoHash = "sha256-qTFRfy+Wutee5SbaMaqcYjXgr6xZKYYBIuyVA7jAGiY=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    OPENSSL_NO_VENDOR = 1;

    doCheck = false;

    meta = {
      description = "AI-powered CLI tool for git commit summaries";
      homepage = "https://github.com/jnsahaj/lumen";
      license = pkgs.lib.licenses.mit;
      mainProgram = "lumen";
      platforms = pkgs.lib.platforms.unix;
    };
  };

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pip
      virtualenv
      requests
    ]
  );

  rubyEnv = pkgs.ruby.withPackages (
    ps: with ps; [
      rspec
      rubocop
      solargraph
    ]
  );
in
{
  home.sessionPath = [
    "$HOME/.local/share/gem/ruby/${pkgs.ruby.version.libDir}/bin"
  ];

  home.packages = with pkgs; [
    claude-code
    dust
    entr
    flyctl
    gh
    graphviz
    hyperfine
    jq
    lazydocker
    mise
    neovim
    opencode
    pandoc
    railway
    sd
    tectonic
    tokei
    tree-sitter
    tmuxinator
    uv
    yq
    zola

    pythonEnv
    rubyEnv

    flow
    kata
    lumen
    revdiff
    cmakelint
  ];
}
