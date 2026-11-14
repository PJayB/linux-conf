#!/bin/bash
set -euo pipefail

die() { echo "$*" >&2; exit 1; }

#
# Installs the niri scrollable-tiling Wayland compositor and a minimal
# supporting stack. Everything comes from the official repos -- no AUR.
#
# niri appears as a session in the display manager alongside any existing
# desktop, so this is safe to install next to COSMIC.
#
# Afterwards, run setup/user-env.sh as your user (before first logging in to
# niri) to drop in config-templates/niri/config.kdl.
#

#
# Checks
#
[[ $EUID -eq 0 ]] || die "Must be root."

pacman -Sy

#
# Refuse to continue if anything would have to come from outside the official
# repos. pacman would fail anyway, but this gives a clearer message.
#
PKGS=(
  # Compositor, plus X11 app support (niri spawns it automatically)
  niri xwayland-satellite

  # Portals: gnome for screencasting/screen sharing, gtk for file pickers
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk

  # Bar, launcher, notifications, wallpaper
  waybar fuzzel mako swaybg

  # Locking and idle
  swaylock swayidle

  # Terminal (bound to Mod+Return)
  alacritty

  # Keyring and polkit agent (niri does not provide one)
  gnome-keyring libsecret polkit polkit-gnome

  # Fonts: Iosevka (alacritty), its Nerd variant, and icon glyphs for the bar
  ttc-iosevka ttf-iosevka-nerd ttf-nerd-fonts-symbols

  # Laptop hardware keys
  brightnessctl wireplumber
)

missing=()
for pkg in "${PKGS[@]}"; do
  pacman -Si "$pkg" &>/dev/null || missing+=("$pkg")
done
[[ ${#missing[@]} -eq 0 ]] || \
  die "Not in the official repos: ${missing[*]}. Not installing."

pacman -S --needed "${PKGS[@]}"

echo "Done. Run setup/user-env.sh as your user, then pick 'Niri' at login."
