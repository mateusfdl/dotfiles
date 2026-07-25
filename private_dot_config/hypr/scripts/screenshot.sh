#!/usr/bin/env bash
set -euo pipefail

readonly SOUND_THEME="freedesktop"
readonly SOUND_MUTED=false

pictures_dir() {
	local resolved
	if [[ -n "${XDG_PICTURES_DIR:-}" ]]; then
		printf '%s\n' "$XDG_PICTURES_DIR"
		return 0
	fi
	if command -v xdg-user-dir >/dev/null 2>&1; then
		resolved=$(xdg-user-dir PICTURES)
		if [[ -n "$resolved" && "$resolved" != "$HOME" ]]; then
			printf '%s\n' "$resolved"
			return 0
		fi
	fi
	printf '%s\n' "$HOME/Pictures"
}

readonly dir="$(pictures_dir)/Screenshots"
timestamp=$(date "+%d-%b_%H-%M-%S")
readonly timestamp
readonly filepath="${dir}/Screenshot_${timestamp}_${RANDOM}.png"

suspend_qs_grabs() {
	qs ipc call launcher suspendGrab >/dev/null 2>&1 || true
}

resume_qs_grabs() {
	qs ipc call launcher resumeGrab >/dev/null 2>&1 || true
}

find_sound() {
	local pattern="$1"
	local system_dir user_dir theme_dir inherit inherit_dir candidate match

	if [[ -d /run/current-system/sw/share/sounds ]]; then
		system_dir="/run/current-system/sw/share/sounds"
	else
		system_dir="/usr/share/sounds"
	fi
	user_dir="$HOME/.local/share/sounds"

	theme_dir="$system_dir/$SOUND_THEME"
	[[ -d "$user_dir/$SOUND_THEME" ]] && theme_dir="$user_dir/$SOUND_THEME"

	inherit=$(sed -n 's/^[[:space:]]*[Ii]nherits[[:space:]]*=[[:space:]]*//p' \
		"$theme_dir/index.theme" 2>/dev/null | head -n1 || true)
	inherit_dir="$theme_dir/../$inherit"

	for candidate in "$theme_dir/stereo" "$inherit_dir/stereo" "$system_dir/$SOUND_THEME/stereo"; do
		match=$(find -L "$candidate" -name "$pattern" -print -quit 2>/dev/null || true)
		if [[ -n "$match" ]]; then
			printf '%s\n' "$match"
			return 0
		fi
	done
	return 1
}

play_sound() {
	[[ "$SOUND_MUTED" == true ]] && return 0

	local event="$1" pattern sound_file
	case "$event" in
		screenshot) pattern="screen-capture.*" ;;
		error) pattern="dialog-error.*" ;;
		*) return 0 ;;
	esac

	sound_file=$(find_sound "$pattern") || return 0
	pw-play "$sound_file" >/dev/null 2>&1 || pa-play "$sound_file" >/dev/null 2>&1 || true
}

capture_result() {
	if [[ -e "$filepath" ]]; then
		play_sound screenshot
	else
		play_sound error
	fi
}

active_geometry() {
	hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

shot_now() {
	grim - | tee "$filepath" | wl-copy || true
	capture_result
}

shot_delayed() {
	sleep "$1"
	grim - | tee "$filepath" | wl-copy || true
	capture_result
}

shot_window() {
	grim -g "$(active_geometry)" - | tee "$filepath" | wl-copy || true
	capture_result
}

shot_area() {
	local tmp
	tmp=$(mktemp)
	if grim -g "$(slurp)" - >"$tmp" && [[ -s "$tmp" ]]; then
		wl-copy <"$tmp"
		mv "$tmp" "$filepath"
		play_sound screenshot
	else
		rm -f "$tmp"
		play_sound error
	fi
}

shot_active() {
	local class path geo
	class=$(hyprctl -j activewindow | jq -r '.class')
	path="${dir}/Screenshot_${timestamp}_${class}.png"
	geo=$(active_geometry)
	if grim -g "$geo" "$path" && [[ -e "$path" ]]; then
		play_sound screenshot
	else
		play_sound error
	fi
}

main() {
	mkdir -p "$dir"
	case "${1:-}" in
		--now) shot_now ;;
		--in5) shot_delayed 5 ;;
		--in10) shot_delayed 10 ;;
		--win) shot_window ;;
		--area) shot_area ;;
		--active) shot_active ;;
		*)
			printf 'Usage: %s {--now|--in5|--in10|--win|--area|--active}\n' \
				"${0##*/}" >&2
			exit 2
			;;
	esac
}

trap resume_qs_grabs EXIT INT TERM
suspend_qs_grabs
main "$@"
