#!/bin/bash

pulse_current_audio_sink() {
    default_sink="$(pactl get-default-sink)"
    [ -n "$default_sink" ] || return
    desc="$(pacmd list-sinks | grep -Pzo \
        "(?s)${default_sink}"'(.*?)device.description = (?-s).*' \
        --color=never | tail -n 1 | cut -f2 -d\")"
    if [ -n "$desc" ]; then
        echo -n ',{"name":"audiosink","full_text":"'"$desc"'"}'
    fi
}

pipewire_current_audio_sink() {
    echo -n ',{"name":"audiosink","full_text":"Pipewire TODO"}'
}

current_audio_sink() {
    if pidof pulseaudio >/dev/null 2>&1 ; then
        pulse_current_audio_sink
    elif pidof pipewire >/dev/null 2>&1 ; then
        pipewire_current_audio_sink
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

