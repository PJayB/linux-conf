#!/bin/bash

# Set the DPI of the display
if [ -f ~/.config/i3/custom-dpi ]; then
    DPI=$(cat ~/.config/i3/custom-dpi)
    echo "Setting DPI to $DPI"
    xrandr --dpi $DPI
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

# Start bluetooth tray
if which blueman-applet; then
    blueman-applet &
fi

# Start a terminal
i3-msg "workspace 1; layout stacking; exec i3-sensible-terminal;"
#if xrandr --listactivemonitors | grep -qE '^ 1:' ; then
#    i3-msg "workspace 2; layout stacking; exec google-chrome"
#else
#    i3-msg "exec google-chrome"
#fi

# Execute custom scripts
CUSTOMSCRIPT=~/.config/i3/custom-startup.sh
if [ -f $CUSTOMSCRIPT ]; then
    /bin/bash "$CUSTOMSCRIPT"
fi

