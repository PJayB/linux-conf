#!/bin/bash

current_audio_sink() {
    sink="$(pacmd list-sinks | grep -Pzo "\* index(.*\n)*" | sed \$d | 
        grep -e "device.description" | cut -f2 -d\")"
    if [ -n "$sink" ]; then
        echo -n ',{"name":"audiosink","full_text":"'"$sink"'"}'
    fi
}

current_media() {
    artist="$(playerctl metadata artist 2>/dev/null)"
    if title="$(playerctl metadata title 2>/dev/null)"; then
        text="🎵 $artist - $title"
        echo -n ',{"name":"media","full_text":"'"${text}"'"}'
    fi
}

i3status | while :
do
    read line
    if echo "$line" | grep -qE '^,?\[.*\]$' ; then
        echo -n "${line%?}"
        current_audio_sink
        current_media
        echo "]"
    else
        echo "$line"
    fi
done

