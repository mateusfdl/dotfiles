{ inputs, ... }:
{
  imports = [ inputs.kata.homeModules.default ];

  programs.kata = {
    enable = true;
    settings = {
      ratchet = true;
      enabled = [
        "go/context-first-param"
        "go/error-strings"
        "go/max-complexity"
        "ts/max-complexity"
        "tsx/max-complexity"
        "go/max-function-length"
        "ts/max-function-length"
        "tsx/max-function-length"
        "go/max-nesting"
        "ts/max-nesting"
        "tsx/max-nesting"
        "ts/no-any"
        "tsx/no-any"
        "ts/no-as-any"
        "tsx/no-as-any"
        "go/no-builtin-print"
        "ts/no-comments"
        "tsx/no-comments"
        "ts/no-console"
        "tsx/no-console"
        "go/no-defer-in-loop"
        "go/no-empty-interface"
        "ts/no-generic-error"
        "tsx/no-generic-error"
        "go/no-init-func"
        "go/no-panic"
        "go/no-swallowed-errors"
        "ts/no-weak-assertions"
        "tsx/no-weak-assertions"
        "go/simple-repositories"
        "ts/simple-repositories"
        "tsx/simple-repositories"
      ];
    };
  };
}
