#!/bin/bash

# Set the DPI of the display
if [ -f ~/.config/i3/custom-dpi ]; then
    DPI=$(cat ~/.config/i3/custom-dpi)
    echo "Setting DPI to $DPI"
    xrandr --dpi $DPI
fi

# Start a terminal
i3-msg "workspace 1; exec i3-sensible-terminal;"

# Execute custom scripts
CUSTOMSCRIPT=~/.config/i3/custom-startup.sh
if [ -f $CUSTOMSCRIPT ]; then
    /bin/bash "$CUSTOMSCRIPT"
fi

