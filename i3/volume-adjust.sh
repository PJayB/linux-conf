#!/bin/sh
DEVFILE=~/.config/i3/pulse-device
if [ ! -f $DEVFILE ]; then
    echo "$DEVFILE not configured!"
    exit 1
fi
if [ "$1" = "" ]; then
    echo "Specify a direction, like +5%, or togglemute."
    exit 1
fi
PDEVICE=$(cat $DEVFILE | grep "^[^#]")
if [ "$1" = "togglemute" ]; then
    pactl set-sink-mute $PDEVICE toggle
else
    pactl set-sink-volume $PDEVICE $1
    pactl set-sink-mute $PDEVICE 0
fi
#killall -USR1 i3status
