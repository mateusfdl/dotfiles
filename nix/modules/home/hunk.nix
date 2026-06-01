{ ... }:
{
  xdg.configFile."hunk/config.toml".text = ''
    theme = "auto"
    mode = "auto"
    watch = true
    exclude_untracked = false
    line_numbers = true
    wrap_lines = false
    agent_notes = false
  '';
}
