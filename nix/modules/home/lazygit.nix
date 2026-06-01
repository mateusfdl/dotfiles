{ ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        overrideGpg = true;
        pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never";
          }
        ];
      };
      notARepository = "quit";
      promptToReturnFromSubprocess = false;
      keybinding.universal.edit = "<c-c>";
      os.editPreset = "nvim";
    };
  };
}
