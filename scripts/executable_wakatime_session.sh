#!/bin/bash

WAKATIME_CONFIG="${HOME}/.wakatime.cfg"
PID_FILE="/tmp/wakatime-daemon.pid"
OUTPUT_FILE="/tmp/wakasession"
DAILY_OUTPUT_FILE="/tmp/wakatotal"
CURRENT_DIR_FILE="/tmp/wakatime-current-dir"
SLEEP_INTERVAL=60

check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Daemon already running with PID $pid"
            exit 1
        fi
        rm -f "$PID_FILE"
    fi
}

create_pid_file() {
    echo $$ > "$PID_FILE"
}

cleanup() {
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

read_config() {
    [ ! -f "$WAKATIME_CONFIG" ] && return 1
    
    local api_key=$(grep -E "^api_key\s*=" "$WAKATIME_CONFIG" | sed 's/^api_key\s*=\s*//' | tr -d ' ')
    local api_url=$(grep -E "^api_url\s*=" "$WAKATIME_CONFIG" | sed 's/^api_url\s*=\s*//' | tr -d ' ')
    
    [ -z "$api_key" ] && return 1
    
    echo "${api_key}|${api_url}"
}

get_project_name() {
    local dir=${1:-$(pwd)}
    
    if [ -f "$CURRENT_DIR_FILE" ]; then
        dir=$(cat "$CURRENT_DIR_FILE")
    fi
    
    if [ -d "$dir" ]; then
        cd "$dir" 2>/dev/null || return
        if git rev-parse --git-dir > /dev/null 2>&1; then
            basename "$(git rev-parse --show-toplevel 2>/dev/null)"
        fi
    fi
}

format_time() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    
    if [ $hours -gt 0 ]; then
        [ $minutes -gt 0 ] && echo "${hours}h ${minutes}m" || echo "${hours}h"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m"
    else
        echo "<1m"
    fi
}

call_api() {
    local endpoint=$1
    local auth_header=$2
    
    local response=$(curl -s "$endpoint" -H "Authorization: ${auth_header}")
    echo "$response" | jq -e . >/dev/null 2>&1 || return 1
    
    local total_seconds=$(echo "$response" | jq -r '.data[0].grand_total.total_seconds // 0' 2>/dev/null)
    [ "$total_seconds" = "0" ] || [ -z "$total_seconds" ] && return 1
    
    local category=$(echo "$response" | jq -r '.data[0].categories[0].name // "Coding"' 2>/dev/null)
    [ -z "$category" ] || [ "$category" = "null" ] && category="Coding"
     
    local lang=$(echo "$response" | jq -r '.data[0].languages[0].name' 2>/dev/null)
    
    echo "${category}|${total_seconds}|${lang}"
}

get_auth_header() {
    if [[ "$WAKATIME_API_URL" == *"wakapi"* ]]; then
        local encoded_key=$(echo -n "${WAKATIME_API_KEY}" | base64)
        echo "Basic ${encoded_key}"
    else
        echo "Bearer ${WAKATIME_API_KEY}"
    fi
}

build_endpoint() {
    local project=$1
    local today=$(date +%Y-%m-%d)
    local base_path
    
    if [[ "$WAKATIME_API_URL" == *"wakapi"* ]]; then
        base_path="/compat/wakatime/v1/users/current/summaries"
    else
        base_path="/v1/users/current/summaries"
    fi
    
    local endpoint="${WAKATIME_API_URL}${base_path}?start=${today}&end=${today}"
    [ -n "$project" ] && endpoint="${endpoint}&project=${project}"
    
    echo "$endpoint"
}

get_project_stats() {
    local project=$1
    local endpoint=$(build_endpoint "$project")
    local auth_header=$(get_auth_header)
    
    local result=$(call_api "$endpoint" "$auth_header")
    [ $? -ne 0 ] && return
    
    local category=$(echo "$result" | cut -d'|' -f1)
    local seconds=$(echo "$result" | cut -d'|' -f2)
    local lang=$(echo "$result" | cut -d'|' -f3)
    local time=$(format_time "$seconds")
    
    echo "${category} ${project} for ${time} in ${lang}"
}

get_daily_stats() {
    local endpoint=$(build_endpoint "")
    local auth_header=$(get_auth_header)
    
    local result=$(call_api "$endpoint" "$auth_header")
    [ $? -ne 0 ] && return
    
    local category=$(echo "$result" | cut -d'|' -f1)
    local seconds=$(echo "$result" | cut -d'|' -f2)
    local time=$(format_time "$seconds")
    
    
    echo "${category} for ${time} in "
}

update_stats() {
    local config=$(read_config)
    if [ -z "$config" ]; then
        echo "" > "$OUTPUT_FILE"
        echo "" > "$DAILY_OUTPUT_FILE"
        return
    fi
    
    WAKATIME_API_KEY=$(echo "$config" | cut -d'|' -f1)
    WAKATIME_API_URL=$(echo "$config" | cut -d'|' -f2)
    
    local project=$(get_project_name)
    if [ -z "$project" ]; then
        echo "" > "$OUTPUT_FILE"
    else
        local result=$(get_project_stats "$project")
        echo "${result:-${project} 0m}" > "$OUTPUT_FILE"
    fi
    
    local daily=$(get_daily_stats)
    echo "${daily}" > "$DAILY_OUTPUT_FILE"
}

main() {
    check_running
    create_pid_file
    
    echo "WakaTime daemon started with PID $$"
    
    while true; do
        update_stats
        sleep "$SLEEP_INTERVAL"
    done
}

main
