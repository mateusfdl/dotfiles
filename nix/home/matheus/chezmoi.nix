{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.chezmoi ];

  home.activation.chezmoiInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.local/share/chezmoi/.git" ]; then
      run ${pkgs.chezmoi}/bin/chezmoi init git@github.com:mateusfdl/dotfiles.git
    fi
  '';
}
