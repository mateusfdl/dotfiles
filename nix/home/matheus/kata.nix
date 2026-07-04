{ inputs, ... }:
{
  imports = [ inputs.kata.homeModules.default ];

  programs.kata = {
    enable = true;
    settings = {
      ratchet = true;
      enabled = [
        "context-first-param"
        "error-strings"
        "max-complexity"
        "max-function-length"
        "max-nesting"
        "no-any"
        "no-as-any"
        "no-builtin-print"
        "no-comments"
        "no-console"
        "no-defer-in-loop"
        "no-empty-interface"
        "no-generic-error"
        "no-init-func"
        "no-panic"
        "no-swallowed-errors"
        "no-weak-assertions"
        "simple-repositories"
      ];
    };
  };
}
