{ pkgs, ... }:
{
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    open-sans
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    material-icons
    material-symbols
  ];
}
