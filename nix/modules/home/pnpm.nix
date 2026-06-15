{ pkgs, ... }:
{
  home.packages = [ pkgs.pnpm ];

  home.sessionVariables = {
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  home.sessionPath = [ "$HOME/.local/share/pnpm" ];
}
