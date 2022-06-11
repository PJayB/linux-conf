#!/bin/bash
DEVFILE=~/.config/i3/brightness-device
if [ ! -f $DEVFILE ]; then
    echo "$DEVFILE not configured!"
    exit 1
fi
if [ "$1" = "" ]; then
    echo "Specify a direction, like +5%."
    exit 1
fi
PDEVICE=$(cat $DEVFILE | grep "^[^#]")
brightnessctl --device="$PDEVICE" set "$1"

