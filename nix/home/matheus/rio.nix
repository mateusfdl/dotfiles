{ ... }:
{
  programs.rio = {
    enable = true;
    settings = {
      theme = "selected";

      fonts = {
        size = 32;
        hinting = false;
        family = "IosevkaSS04 Nerd Font Mono";
        regular = {
          weight = 500;
          style = "Medium";
        };
      };
    };
  };
}
