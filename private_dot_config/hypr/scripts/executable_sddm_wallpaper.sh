#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# SDDM Wallpaper and Wallust Colors Setter

# for the upcoming changes on the simple_sddm_theme

# variables
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_modified="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
hyprlock_wallpaper="$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark/Fuji-Dark.png"
sddm_simple="/usr/share/sddm/themes/simple_sddm_2"

# sddm colors path
sddm_theme_conf="$sddm_simple/theme.conf"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# Parse arguments
mode="effects" # default
if [[ "$1" == "--normal" ]]; then
    mode="normal"
elif [[ "$1" == "--effects" ]]; then
    mode="effects"
fi

# Colors matching hyprlock setup (white/light theme)
# Using rgba colors from hyprlock configuration
color_white="#ffffff"              # Pure white for main text
color_white_hex="#cccccc"          # Hex white for icons (Qt icon.color compatibility)
color_white_70="rgba(255,255,255,0.7)"   # 70% opacity white for subtle text
color_white_80="rgba(255,255,255,0.8)"   # 80% opacity white
color_white_35="rgba(255,255,255,0.35)"  # 35% opacity for borders
color_white_12="rgba(255,255,255,0.12)"  # 12% opacity for backgrounds
color_capslock="#ff5555"           # Red for capslock warning

# wallpaper to use (matching hyprlock background)
wallpaper_path="$hyprlock_wallpaper"

# Launch terminal and apply changes
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';

# Create backup of theme.conf with timestamp
timestamp=\$(date +%Y%m%d_%H%M%S)
backup_file=\"backup.theme.\${timestamp}.conf\"
echo 'Creating backup of theme.conf...'
sudo cp \"$sddm_theme_conf\" \"$sddm_simple/\$backup_file\"
echo \"Backup created: \$backup_file\"

# Update screen resolution to 4K (matching DP-3 monitor)
sudo sed -i 's/ScreenWidth=\".*\"/ScreenWidth=\"3840\"/' \"$sddm_theme_conf\"
sudo sed -i 's/ScreenHeight=\".*\"/ScreenHeight=\"2160\"/' \"$sddm_theme_conf\"

# Adjust font size for smaller, cleaner inputs (matching hyprlock's minimal design)
sudo sed -i 's/FontSize=\".*\"/FontSize=\"18\"/' \"$sddm_theme_conf\"

# Update time and date format to match hyprlock
sudo sed -i 's/HourFormat=\".*\"/HourFormat=\"HH:mm\"/' \"$sddm_theme_conf\"
sudo sed -i 's/DateFormat=\".*\"/DateFormat=\"dddd d MMMM\"/' \"$sddm_theme_conf\"

# Position form in center (matching hyprlock centered layout)
sudo sed -i 's/FormPosition=\".*\"/FormPosition=\"center\"/' \"$sddm_theme_conf\"

# Disable header text (hyprlock doesn't have one)
sudo sed -i 's/HeaderText=\".*\"/HeaderText=\"\"/' \"$sddm_theme_conf\"

# Update the colors in the SDDM config (matching hyprlock white/light theme)
sudo sed -i \"s/HeaderTextColor=\\\"#.*\\\"/HeaderTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DateTextColor=\\\"#.*\\\"/DateTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/TimeTextColor=\\\"#.*\\\"/TimeTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SystemButtonsIconsColor=\\\"#.*\\\"/SystemButtonsIconsColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SessionButtonTextColor=\\\"#.*\\\"/SessionButtonTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/VirtualKeyboardButtonTextColor=\\\"#.*\\\"/VirtualKeyboardButtonTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/LoginFieldTextColor=\\\"#.*\\\"/LoginFieldTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordFieldTextColor=\\\"#.*\\\"/PasswordFieldTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightTextColor=\\\"#.*\\\"/HighlightTextColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"

# Background and border colors with transparency effect (matching hyprlock input field)
sudo sed -i \"s/LoginFieldBackgroundColor=\\\"#.*\\\"/LoginFieldBackgroundColor=\\\"$color_white_12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordFieldBackgroundColor=\\\"#.*\\\"/PasswordFieldBackgroundColor=\\\"$color_white_12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DropdownBackgroundColor=\\\"#.*\\\"/DropdownBackgroundColor=\\\"$color_white_12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DropdownSelectedBackgroundColor=\\\"#.*\\\"/DropdownSelectedBackgroundColor=\\\"$color_white_35\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightBackgroundColor=\\\"#.*\\\"/HighlightBackgroundColor=\\\"$color_white_35\\\"/\" \"$sddm_theme_conf\"

# Placeholder and icon colors (subtle - matching hyprlock)
sudo sed -i \"s/PlaceholderTextColor=\\\".*\\\"/PlaceholderTextColor=\\\"$color_white_70\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/UserIconColor=\\\".*\\\"/UserIconColor=\\\"$color_white_hex\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordIconColor=\\\".*\\\"/PasswordIconColor=\\\"$color_white_hex\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HoverUserIconColor=\\\".*\\\"/HoverUserIconColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HoverPasswordIconColor=\\\".*\\\"/HoverPasswordIconColor=\\\"$color_white\\\"/\" \"$sddm_theme_conf\"

# Background settings (matching hyprlock blur and effects)
sudo sed -i 's/PartialBlur=\".*\"/PartialBlur=\"true\"/' \"$sddm_theme_conf\"
sudo sed -i 's/HaveFormBackground=\".*\"/HaveFormBackground=\"false\"/' \"$sddm_theme_conf\"

# Copy wallpaper to SDDM theme
sudo cp \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default\"

notify-send -i \"$iDIR/ja.png\" \"SDDM\" \"Background SET\"
"
