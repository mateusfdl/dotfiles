# Theme templates

These are the only terminal/tmux templates.

`/home/matheus/scripts/switch-theme-mode` selects a JSON palette from:

- `/home/matheus/scripts/themes/dark/<theme>.json`
- `/home/matheus/scripts/themes/light/<theme>.json`

Then it uses `jq` to replace template placeholders and applies the rendered result:

- Tmux: replaces the managed block in `~/.tmux/theme.conf`
- Kitty: writes `~/.config/kitty/theme.conf`
- Alacritty: writes `~/.config/alacritty/themes/.selected_theme.toml`
- Ghostty: writes `~/.config/ghostty/themes/<theme>`, then points `~/.config/ghostty/switch-theme` at it (`theme=<theme>`) and reloads the config
- Rio: writes `~/.config/rio/themes/selected.toml`, then writes the theme name to `~/.config/rio/.theme-reload`

Rio notes: `~/.config/rio/config.toml` comes from Home Manager (`nix/home/matheus/rio.nix`) and
holds `theme = "selected"`, so the rendered file always keeps the same name. Rio watches
`~/.config/rio` without recursion, so a write inside `themes/` alone does not reload the config.
The `.theme-reload` write happens in the watched directory and makes Rio read the theme file again.

Ghostty notes: the rendered file is a Ghostty theme (one `palette = N=#hex` line per
ANSI slot plus `background`/`foreground`/`cursor-color`/`selection-*`). Ghostty resolves
`theme=<name>` by looking up a file of that name in `~/.config/ghostty/themes/`, so the
generated file and the `switch-theme` include stay in sync automatically.

Placeholder format maps directly to JSON paths:

```text
{{ theme.name }}
{{ theme.type }}
{{ base30.white }}
{{ base16.base00 }}
```

Example:

```tmux
white='{{ base30.white }}'
```

There are no generated per-theme terminal files. The JSON palette is the theme; these templates are app-agnostic schemas.
