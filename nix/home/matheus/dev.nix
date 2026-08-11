{ pkgs, ... }:
let
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
    sqlite
    tectonic
    tokei
    tree-sitter
    tmuxinator
    uv
    yq
    zola

    pythonEnv
    rubyEnv

    cmakelint
  ];
}
