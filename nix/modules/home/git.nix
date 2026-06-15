{ ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      user.email = "matheus.limastack@gmail.com";
      user.name = "Matheus Lima";
    };
  };
}
