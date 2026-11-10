{ pkgs, ... }:
let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pip
      virtualenv
      requests
    ]
  );

  rubyEnv = pkgs.ruby.withPackages (_: builtins.attrValues (pkgs.ruby.buildGems ./ruby/gemset.nix));
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
