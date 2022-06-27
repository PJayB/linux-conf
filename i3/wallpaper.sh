#!/bin/bash
die() {
    notify-send "❌ $*"
    exit 1
}

case "$1" in
trash)
    if variety -t; then
        notify-send "🗑 Wallpaper trashed."
    else
        die "Failed to trash wallpaper."
    fi
    ;;
fav|favorite)
    if variety -f; then
        notify-send "Wallpaper favorited. 💜"
    else
        die "Failed to favorite wallpaper."
    fi
    ;;
next)
    if variety -n; then
        notify-send "➡ Wallpaper skipped."
    else
        die "Failed to skip wallpaper."
    fi
    ;;
*)
    die "Wot dis? '$1'"
    ;;
esac

