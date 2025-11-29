#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl

music_icon="$HOME/.config/swaync/icons/music.png"

play_next() {
    playerctl next
    show_music_notification
}

play_previous() {
    playerctl previous
    show_music_notification
}

toggle_play_pause() {
    playerctl play-pause
    show_music_notification
}

stop_playback() {
    playerctl stop
    notify-send -e -u low -i $music_icon " Playback:" " Stopped"
}

show_music_notification() {
    status=$(playerctl status)
    if [[ "$status" == "Playing" ]]; then
        song_title=$(playerctl metadata title)
        song_artist=$(playerctl metadata artist)
        notify-send -e -u low -i $music_icon "Now Playing:" "$song_title by $song_artist"
    elif [[ "$status" == "Paused" ]]; then
        notify-send -e -u low -i $music_icon " Playback:" " Paused"
    fi
}

case "$1" in
    "--nxt")
        play_next
        ;;
    "--prv")
        play_previous
        ;;
    "--pause")
        toggle_play_pause
        ;;
    "--stop")
        stop_playback
        ;;
    *)
        echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
        exit 1
        ;;
esac
