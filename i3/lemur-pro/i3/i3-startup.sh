#!/bin/bash

# Set monitor layout
if xrandr --properties | grep -qE '^DP-[[:number:]] connected'; then
    "$HOME/.screenlayout/acer-32-left-of-laptop.sh"
fi

