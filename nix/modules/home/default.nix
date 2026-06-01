{ ... }:
{
  imports = [
    ./lazygit.nix
    ./bat.nix
    ./btop.nix
    ./hunk.nix
  ];

  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;
}
