#!/bin/bash
pkill yad || true

if pidof rofi > /dev/null; then
  pkill rofi
fi

keybinds_conf="$HOME/.config/hypr/configs/keybinds.conf"
user_keybinds_conf="$HOME/.config/hypr/user/keybinds.conf"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"

keybinds=$(cat "$keybinds_conf" "$user_keybinds_conf" | grep -E '^bind')

if [[ -z "$keybinds" ]]; then
    echo "no keybinds found."
    exit 1
fi

display_keybinds=$(echo "$keybinds" | sed 's/\$mainMod/SUPER/g')

echo "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
