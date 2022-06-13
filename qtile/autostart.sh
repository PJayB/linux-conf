#!/bin/bash
log_tag="qtile-autostart"

die() {
    # print to syslog & stderr
    logger -t "$log_tag" -s "$*"

    # abort
    exit 1
}

logdir="$HOME/.config/qtile-autostart-logs"
mkdir -p "$logdir" || die "Failed to create $logdir"

pids=( )

run_detached() {
    name="$(basename "$1")"
    [ -n "$name" ] || die "Couldn't detect base name of '$1'"
    logger -t "$log_tag" "Starting: $*"
    nohup "$@" </dev/null >"$logdir/$name.log" 2>&1 &
    pids+=( $! )
}

run_detached xss-lock --transfer-sleep-lock -- i3lock --show-failed-attempts --ignore-empty-password --color=060015
run_detached picom --experimental-backends --config ~/.config/i3/picom.conf -b
run_detached variety
run_detached blueman-applet
run_detached nm-applet
run_detached dunst

