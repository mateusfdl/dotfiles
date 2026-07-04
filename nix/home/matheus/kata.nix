{ inputs, ... }:
{
  imports = [ inputs.kata.homeModules.default ];

  programs.kata = {
    enable = true;
    settings = {
      ratchet = true;
    };
  };
}
