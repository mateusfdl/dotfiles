# Theme templates

These are the only terminal/tmux templates.

`/home/matheus/scripts/switch-theme-mode` selects a JSON palette from:

- `/home/matheus/scripts/themes/dark/<theme>.json`
- `/home/matheus/scripts/themes/light/<theme>.json`

Then it uses `jq` to replace template placeholders and applies the rendered result:

- Tmux: replaces the managed block in `~/.tmux/theme.conf`
- Kitty: writes `~/.config/kitty/theme.conf`
- Alacritty: writes `~/.config/alacritty/themes/.selected_theme.toml`

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
