if pidof rofi > /dev/null; then
  pkill rofi
fi

iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
monitor_dir="$HOME/.config/hypr/monitor"
target="$HOME/.config/hypr/monitors.conf"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg='❗NOTE:❗ This will overwrite $HOME/.config/hypr/monitors.conf'

ignore_files=( "README")

chosen_file=$(echo "$mon_profiles_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    full_path="$monitor_dir/$chosen_file.conf"
    cp "$full_path" "$target"
    
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/refresh-no-waybar.sh &
