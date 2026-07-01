#!/usr/bin/env bash

SOCK="$(ls /run/user/1000/hypr/*/.socket2.sock)"
prev=""

socat - UNIX-CONNECT:"$SOCK" | while read -r _; do
  cur=$(hyprctl activewindow -j | jq -c '{
    addr: .address,
    class: .class,
    title: .title,
    app: .initialClass,
    floating: .floating,
    at,
    size
  }')

  if [[ "$cur" != "$prev" ]]; then
    echo "GEOMETRY CHANGED: $cur"
    prev="$cur"
  fi
done

