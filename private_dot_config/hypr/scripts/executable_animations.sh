#!/bin/bash
if pidof rofi > /dev/null; then
  pkill rofi
fi

iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/user"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ This will copy animations into UserAnimations.conf'
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.conf"    
    cp "$full_path" "$UserConfigs/animations.conf"    
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Hyprland Animation Loaded"
fi

sleep 1
"$SCRIPTSDIR/refresh-no-waybar.sh"
