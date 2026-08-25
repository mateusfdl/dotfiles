{ ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        overrideGpg = true;
        diffRenderers = [
          {
            colorArg = "always";
            command = "delta --paging=never";
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
