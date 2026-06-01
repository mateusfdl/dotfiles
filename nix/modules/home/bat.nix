{ ... }:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      "italic-text" = "always";
      paging = "never";
    };
  };
}
