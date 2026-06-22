{ ... }:
{
  imports = [
    ./lazygit.nix
    ./bat.nix
    ./btop.nix
    ./chezmoi.nix
    ./cli.nix
    ./dev.nix
    ./direnv.nix
    ./git.nix
    ./hunk.nix
    ./pnpm.nix
  ];

  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;
}
