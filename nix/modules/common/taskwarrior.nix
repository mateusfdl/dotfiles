{ pkgs, ... }:
let
  taskwarriorConfig = pkgs.writeText "taskrc" ''
    include /home/matheus/Documents/personal-org-mode/Personal/Journal/todos/taskrc
    data.location=~/.task
    uda.repeat.type=string
    uda.repeat.label=Repeat.Enabled
    uda.repeat.values=yes,no
    uda.consistent.type=string
    uda.consistent.label=Repeat.Consistent
    uda.consistent.values=yes,no
    uda.delta.type=numeric
    uda.delta.label=Repeat.Delta
    uda.severity.type=string
    uda.severity.label=Severity
    uda.severity.values=critical,high,medium,low
  '';
  taskwarriorAsTaskw = pkgs.writeShellScriptBin "taskw" ''
    exec ${pkgs.taskwarrior3}/bin/task rc:${taskwarriorConfig} "$@"
  '';
in
{
  environment.systemPackages = [ taskwarriorAsTaskw ];
}
