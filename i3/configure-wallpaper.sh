#!/bin/bash
nitrogen /usr/share/backgrounds || exit 1

SUSCRIPT=~/.config/i3/custom-startup.sh

if ! grep -q "nitrogen" $SUSCRIPT 2>/dev/null; then
  cat >> $SUSCRIPT << EOL

# Restore wallpaper state
exec nitrogen --restore
EOL
fi

chmod +x $SUSCRIPT
