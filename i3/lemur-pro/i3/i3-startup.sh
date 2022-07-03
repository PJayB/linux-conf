#!/bin/bash
die() {
    # print to syslog & stderr
    echo "$*" >&2

    # abort
    exit 1
}

logdir="$HOME/.cache/i3-autostart-logs"
mkdir -p "$logdir" || die "Failed to create $logdir"

# Redirect this script's output to a file
if [ ! -t 0 ]; then
    exec >"$logdir/autostart.log" 2>&1
fi

pids=( )

run_detached() {
    name="$(basename "$1")"
    [ -n "$name" ] || die "Couldn't detect base name of '$1'"
    echo "Starting: $*"
    nohup "$@" </dev/null >"$logdir/$name.log" 2>&1 &
    pids+=( $! )
}

# Set monitor layout
if xrandr --properties | grep -qE '^DP-[[:digit:]] connected'; then
    "$HOME/.screenlayout/acer-32-left-of-laptop.sh"
fi

dunst_config_dir="$HOME/.config/dunst"
i3_config_dir="$HOME/.config/i3"

# Hand off suspend to lock screen
run_detached xss-lock --transfer-sleep-lock -- "$i3_config_dir/lock.sh"

# Start compositor
run_detached picom --experimental-backends --config "$i3_config_dir/picom.conf" -b

# Restore wallpaper
run_detached variety --resume

# Start bluetooth applet
run_detached blueman-applet

# Start network applet
run_detached nm-applet

# Start dunst
run_detached dunst -config "$dunst_config_dir/dunstrc"

# Set Caps Lock to mean escape
#setxkbmap -layout us -option caps:escape

echo "Done."

