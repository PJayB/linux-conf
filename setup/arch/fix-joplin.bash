#!/bin/bash
# Joplin seems to have a bug where it refuses to open a second time when this
# config file exists (even though the contents are sane). This script works
# around this issue by ensuring the config file is always empty.
CONFIGFILE=~/.config/joplin_desktop/window-state-prod.json
mkdir -p "$(dirname "$CONFIGFILE")"
echo "" > "$CONFIGFILE"
chmod u-rw "$CONFIGFILE"
