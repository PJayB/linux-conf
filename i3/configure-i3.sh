#!/bin/bash
set -e

I3=~/.config/i3

mkdir -p $I3
mkdir -p ~/.config/i3status
mkdir -p ~/.config/dunst

cd $(dirname $0)

copy_or_merge() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ]; then
        if diff "$src" "$dst" ; then
            echo "$src and $dst are the same. Skipping."
        else
            echo "$dst exists... merging."
            cp "$dst" "$dst.bak"
            git merge-file --union "$dst" /dev/null "$src" || echo "Merge failed!" >&2
        fi
    else
        cp -v "$src" "$dst"
    fi
}

# Pick up the pulse audio device (if it exists) and merge it into a temporary i3status file
# that we'll use for merging
pulsedevicefile="$HOME/.config/i3/pulse-device"
i3statusconf="./i3status-config"
if [ -e "$pulsedevicefile" ]; then
    pulsedevice="$(cat "$pulsedevicefile")"
    tmpstatusconf="/tmp/i3status.tmp"
    sed -r "s/\"pulse:.*\"/\"pulse:$pulsedevice\"/g" "$i3statusconf" > "$tmpstatusconf"
    i3statusconf="$tmpstatusconf"
fi

copy_or_merge ./i3-config $I3/config
copy_or_merge "$i3statusconf" ~/.config/i3status/config
cp -v ./volume-adjust.sh $I3/volume-adjust.sh
cp -v ./i3-startup.sh $I3/i3-startup.sh
cp -v ./lock.sh $I3/lock.sh
cp -v ./dunstrc ~/.config/dunst/dunstrc
cp -v ./screenshot.sh $I3/screenshot.sh
cp -v ./picom.conf $I3/picom.conf

echo "NOTE: If you want DPI scaling, output your DPI to $I3/custom-dpi"

# Restart dunst to pick up the dunstrc
killall dunst; notify-send "i3 Configured!"

# Warn if arandr is not installed
[ -e /usr/bin/arandr ] || echo "NOTE: Don't forget to install arandr if you want better multimonitor config"

# Set up pulse (or try, anyway)
./pulse-setup.sh || echo "Please run pulse-setup.sh again to fix volume control"
