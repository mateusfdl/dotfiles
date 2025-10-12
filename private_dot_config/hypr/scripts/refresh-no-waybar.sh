#!/bin/bash
SCRIPTSDIR=$HOME/.config/hypr/scripts
scripts=$HOME/.config/hypr/scripts

file_exists() {
    if [ -e "$1" ]; then
        return 0   
    else
        return 1  
    fi
}

_ps=(rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

pkill qs && qs &

${SCRIPTSDIR}/WallustSwww.sh &

swaync-client --reload-config

exit 0
