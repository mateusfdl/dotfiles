#!/bin/bash

CURRENT_DIR_FILE="/tmp/wakatime-current-dir"
OUTPUT_FILE="/tmp/wakasession"

current_dir=$(tmux display-message -p '#{pane_current_path}')
echo "$current_dir" > "$CURRENT_DIR_FILE"

cat "$OUTPUT_FILE" 2>/dev/null || echo ""
