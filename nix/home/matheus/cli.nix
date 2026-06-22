{ ... }:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fd.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.ripgrep.enable = true;
  programs.tmux = {
    enable = true;
    clock24 = true;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
  };
}
