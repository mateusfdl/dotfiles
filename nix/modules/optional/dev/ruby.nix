{ pkgs, ... }:
{
  environment.sessionVariables.PATH = [
    "$HOME/.local/share/gem/ruby/${pkgs.ruby.version.libDir}/bin"
    "$PATH"
  ];

  environment.systemPackages = [
    (pkgs.ruby.withPackages (
      ps: with ps; [
        rspec
        rubocop
        solargraph
      ]
    ))
    pkgs.tmuxinator
  ];
}
