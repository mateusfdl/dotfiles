#!/bin/bash
iDIR="$HOME/.config/swaync/images"

if ! command -v kitty &> /dev/null; then
  notify-send -i "$iDIR/error.png" "Need Kitty:" "Kitty terminal not found. Please install Kitty terminal."
  exit 1
fi

if command -v paru &> /dev/null || command -v yay &> /dev/null; then
  if command -v paru &> /dev/null; then
    kitty -T update paru -Syu
    notify-send -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  fi
