#!/bin/bash
wpaper="$HOME/.config/i3/lock-screen.png"
if which betterlockscreen ; then
    if [ -f "$wpaper" ]; then
        wpaper=( dim -u "$wpaper" )
    else
        wpaper=( color "--color" "000000")
    fi
    betterlockscreen -l "${wpaper[@]}"
else
    if [ -f "$wpaper" ]; then
        wpaper=("--image=$wpaper" "--tiling")
    else
        wpaper=("--color=000000")
    fi
    i3lock --show-failed-attempts --ignore-empty-password "${wpaper[@]}"
fi

