{ inputs, ... }:
let
  error = {
    enabled = true;
    severity = "error";
  };
in
{
  imports = [ inputs.kata.homeModules.default ];

  programs.kata = {
    enable = true;
    settings = {
      ratchet = true;
      rules = {
        go = {
          context-first-param = error;
          error-strings = error;
          max-complexity = error;
          max-function-length = error;
          max-nesting = error;
          no-builtin-print = error;
          no-defer-in-loop = error;
          no-empty-interface = error;
          no-init-func = error;
          no-panic = error;
          no-swallowed-errors = error;
          simple-repositories = error;
        };
        typescript = {
          max-complexity = error;
          max-function-length = error;
          max-nesting = error;
          no-any = error;
          no-as-any = error;
          no-comments = error;
          no-console = error;
          no-generic-error = error;
          no-weak-assertions = error;
          simple-repositories = error;
        };
      };
    };
  };
}
