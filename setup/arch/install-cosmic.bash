#!/bin/bash
set -euo pipefail

die() { echo "$*" >&2; exit 1; }

#
# Checks
#
[[ $EUID -eq 0 ]] || die "Must be root."

#
# Enable multilib and sync repos (must happen before any pacman -Si probing)
#
sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
pacman -Sy
pacman -S --needed pciutils

#
# Detect GPU and select Vulkan packages
#
detect_gpu() {
  local display
  display="$(lspci | grep -iE 'VGA|3D|Display')"
  if echo "$display" | grep -qi 'AMD\|ATI'; then
    echo amd
  elif echo "$display" | grep -qi nvidia; then
    echo nvidia
  elif echo "$display" | grep -qi intel; then
    echo intel
  else
    echo unknown
  fi
}

GPU="$(detect_gpu)"
echo "Detected GPU: $GPU"

case "$GPU" in
  amd)    VULKAN_PKGS=(vulkan-radeon lib32-vulkan-radeon \
                      mesa lib32-mesa vulkan-tools) ;;
  intel)  VULKAN_PKGS=(vulkan-intel  lib32-vulkan-intel \
                      mesa lib32-mesa vulkan-tools) ;;
  nvidia) VULKAN_PKGS=(nvidia nvidia-utils lib32-nvidia-utils \
                      vulkan-tools) ;;
  *)
    echo "WARNING: Could not detect GPU vendor. Install Vulkan drivers " \
      "manually." >&2
    VULKAN_PKGS=()
    ;;
esac

#
# Resolve distro-variable package names
#
first_available_pkg() {
  for pkg in "$@"; do
    if pacman -Si "$pkg" &>/dev/null; then
      echo "$pkg"
      return
    fi
  done
  die "None of the following packages found in repos: $*"
}

COSMIC_PKG="$(first_available_pkg cosmic cosmic-session)"
PORTAL_PKG="$(first_available_pkg xdg-desktop-portal-cosmic \
  xdg-desktop-portal-gtk)"

#
# Aggregate and install all packages
#
PKGS=(
  # COSMIC desktop and greeter
  "$COSMIC_PKG" cosmic-greeter
  "$(first_available_pkg cosmic-term cosmic-terminal)"
  "$(first_available_pkg cosmic-edit cosmic-text-editor)"
  cosmic-store cosmic-wallpapers

  # Keyring and polkit
  gnome-keyring libsecret polkit polkit-gnome

  # Audio
  pipewire pipewire-pulse pipewire-alsa wireplumber

  # Bluetooth
  bluez bluez-utils

  # Vulkan (GPU-specific, may be empty)
  "${VULKAN_PKGS[@]+"${VULKAN_PKGS[@]}"}"

  # Steam and gaming utilities
  steam gamemode lib32-gamemode

  # Fonts
  noto-fonts noto-fonts-emoji ttf-liberation

  # Browser
  firefox

  # XDG user directories
  xdg-user-dirs

  # Flatpak and desktop portal
  flatpak "$PORTAL_PKG"

  # Plymouth
  plymouth
)

pacman -S --needed "${PKGS[@]}"

#
# Post-install configuration
#
systemctl --global enable pipewire.service pipewire-pulse.service \
  wireplumber.service
systemctl enable --now bluetooth
systemctl enable cosmic-greeter

flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

sed -i 's/\(HOOKS=(base systemd\)/\1 plymouth/' /etc/mkinitcpio.conf
sed -i 's/\(^options .*\)$/\1 quiet splash/' /boot/loader/entries/manjaro.conf
plymouth-set-default-theme -R spinner

echo "Done. Reboot."
