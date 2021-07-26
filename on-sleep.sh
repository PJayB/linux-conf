#!/bin/bash
#
# Copy this to /lib/systemd/system-sleep and make sure it's executable
#

# "post" is the /lib/systemd/system-sleep signal that the PC has resumed from sleep
# "resume" is the /usr/lib/pm-utils/sleep.d signal that the PC has resumed from sleep
if [ "$1" != "post" ] && [ "$1" != "resume" ]; then
  exit 0
fi

exec 1>/tmp/on-sleep.log 2>&1

# Reset monitor configuration
# primary_monitor=...
# secondary_monitor=...
# xrandr --output "$primary_monitor" --auto --preferred --pos 0x0 --panning 0x0 --screen 0 --size 2560x1440 --output "$secondary_monitor" --auto --preferred --right-of "$primary_monitor"

# Reset audio device if needed (use pactl list to figure this out)
# pactl set-default-source alsa_output.pci-0000_04_00.1.hdmi-surround-extra1.monitor

# Restart chrome GPU processes after PC wakes up
/home/pete/setup-scripts/tools/restore-chrome.sh

