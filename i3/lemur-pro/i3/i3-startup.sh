#!/bin/bash

# Set monitor layout
if xrandr --properties | grep -qE '^DP-1 connected'; then
    "$HOME/.screenlayout/acer-32-left-of-laptop.sh"
fi

# Start compositor
if which picom && ! pgrep -x picom; then
    picom --experimental-backends --config ~/.config/i3/picom.conf -b
fi

# Reset wallpaper
if which nitrogen; then
    nitrogen --restore
fi

# Start pulseaudio
start-pulseaudio-x11

# Start a terminal
i3-msg "workspace 1; layout stacking; exec i3-sensible-terminal;"


