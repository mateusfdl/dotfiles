#!/bin/bash

TMUX_THEME_DIR="$HOME/.tmux/themes"
TMUX_THEME_FILE="$HOME/.tmux/theme.conf"
ALACRITTY_THEME_DIR="$HOME/.config/alacritty/themes"
ALACRITTY_THEME_FILE="$ALACRITTY_THEME_DIR/.selected_theme.toml"
KITTY_THEME_DIR="$HOME/.config/kitty/themes"
KITTY_THEME_FILE="$HOME/.config/kitty/theme.conf"

GHOSTTY_FILE_TOGGLER="$HOME/.config/ghostty/switch-theme"

TMP_MODE_FILE="/tmp/theme-mode"

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -n "$(command -v wsl.exe)" ] || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

switch_macos_theme() {
    local mode="$1"
    if [ "$mode" = "light" ]; then
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
        echo "Switched macOS to light mode"
    else
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
        echo "Switched macOS to dark mode"
    fi
}

switch_windows_theme() {
    local mode="$1"
    if [ "$mode" = "light" ]; then
        powershell.exe -Command "
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 1;
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 1
        " 2>/dev/null
        echo "Switched Windows to light mode"
    else
        powershell.exe -Command "
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0;
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 0
        " 2>/dev/null
        echo "Switched Windows to dark mode"
    fi
}

switch_linux_theme() {
    local mode="$1"
    if command -v gsettings >/dev/null 2>&1; then
        if [ "$mode" = "light" ]; then
            gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Dark'
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            echo "Switched GNOME to light mode"
        else
            gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Dark'
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            echo "Switched GNOME to dark mode"
        fi
    else
        echo "Linux theme switching not implemented for this desktop environment"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"

if [ -f "$TMP_MODE_FILE" ]; then
    CURRENT_MODE=$(cat "$TMP_MODE_FILE")
else
    CURRENT_MODE="dark"
    echo "dark" > "$TMP_MODE_FILE"
fi

if [ "$CURRENT_MODE" = "light" ]; then
    NEW_MODE="dark"
    SELECTED_THEME=$DARK_THEME
else
    NEW_MODE="light"
    SELECTED_THEME=$LIGHT_THEME
fi

if [ -f "$TMUX_THEME_DIR/$SELECTED_THEME" ]; then
    cp "$TMUX_THEME_DIR/$SELECTED_THEME" "$TMUX_THEME_FILE"
    if command -v tmux >/dev/null 2>&1; then
        tmux source-file "$TMUX_THEME_FILE" 2>/dev/null || echo "Tmux not running or failed to source theme"
    fi
else
    echo "Tmux theme file $SELECTED_THEME not found in $TMUX_THEME_DIR!"
fi

if [ -f "$GHOSTTY_FILE_TOGGLER" ]; then
  echo "theme=$SELECTED_THEME" > $GHOSTTY_FILE_TOGGLER
  osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar item "Ghostty" of menu bar 1'

fi

if [ -f "$ALACRITTY_THEME_DIR/$SELECTED_THEME.toml" ]; then
    cp "$ALACRITTY_THEME_DIR/$SELECTED_THEME.toml" "$ALACRITTY_THEME_FILE"
else
    echo "Alacritty theme file $SELECTED_THEME.toml not found in $ALACRITTY_THEME_DIR!"
fi

if [ -f "$KITTY_THEME_DIR/$NEW_MODE.conf" ]; then
    cp "$KITTY_THEME_DIR/$NEW_MODE.conf" "$KITTY_THEME_FILE"
    if command -v pgrep >/dev/null 2>&1; then
        pgrep kitty | xargs -I {} kill -SIGUSR1 {} 2>/dev/null
    fi
else
    echo "Kitty theme file $SELECTED_THEME.conf not found in $KITTY_THEME_DIR!"
fi

case "$OS" in
    "macos")
        switch_macos_theme "$NEW_MODE"
        ;;
    "wsl")
        LOCAL_APP_DATA=$(powershell.exe -Command '[Environment]::GetFolderPath("LocalApplicationData")' 2>/dev/null | tr -d '\r')
        TERMINAL_SETTINGS_FILE=$(wslpath "${LOCAL_APP_DATA}\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json" 2>/dev/null)
        
        if [ -f "$TERMINAL_SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
            jq --arg theme "$SELECTED_THEME" '.profiles.list |= map(if has("colorScheme") then .colorScheme = $theme else . end)' "$TERMINAL_SETTINGS_FILE" > settings.tmp && mv settings.tmp "$TERMINAL_SETTINGS_FILE"
        else
            [ ! -f "$TERMINAL_SETTINGS_FILE" ] && echo "Windows Terminal settings file not found!"
            [ ! command -v jq >/dev/null 2>&1 ] && echo "jq not found, skipping Windows Terminal theme switch"
        fi
        
        switch_windows_theme "$NEW_MODE"
        ;;
    "linux")
        switch_linux_theme "$NEW_MODE"
        ;;
    *)
        echo "OS-specific theme switching not supported for: $OS"
        ;;
esac

if command -v pgrep >/dev/null 2>&1; then
    pgrep nvim | xargs -n1 kill -SIGUSR1 2>/dev/null
elif command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR1 nvim 2>/dev/null
fi

echo "$NEW_MODE" > "$TMP_MODE_FILE"
echo "Theme switched to $NEW_MODE mode on $OS"
