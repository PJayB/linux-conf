#!/bin/sh
PDEVICE="$(pactl get-default-sink)"
if [ "$1" = "togglemute" ]; then
    pactl set-sink-mute $PDEVICE toggle
else
    pactl set-sink-volume $PDEVICE $1
    pactl set-sink-mute $PDEVICE 0
fi

