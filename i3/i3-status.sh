#!/bin/bash

current_audio_sink() {
    default_sink="$(pactl get-default-sink)"
    [ -n "$default_sink" ] || return
    desc="$(pacmd list-sinks | grep -Pzo \
        "(?s)${default_sink}"'(.*?)device.description = (?-s).*' \
        --color=never | tail -n 1 | cut -f2 -d\")"
    if [ -n "$desc" ]; then
        echo -n ',{"name":"audiosink","full_text":"'"$desc"'"}'
    fi
}

current_media() {
    artist="$(playerctl metadata artist 2>/dev/null)"
    if title="$(playerctl metadata title 2>/dev/null)"; then
        text="🎵 $artist - $title"
        echo -n ',{"name":"media","full_text":"'"${text}"'"}'
    fi
}

i3status "$@" | while :
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

