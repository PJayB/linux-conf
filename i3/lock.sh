#!/bin/bash
wpaper="$HOME/.config/i3/lock-screen.png"
#$(gsettings get org.gnome.desktop.background picture-uri | sed -nr "s|'file://(.*)'|\1|p")
if [ -f "$wpaper" ]; then
    wpaper=("--image=$wpaper" "--tiling")
else
    wpaper=("--color=000000")
fi
i3lock --show-failed-attempts --ignore-empty-password "${wpaper[@]}"
