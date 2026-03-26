#!/bin/bash
# Post-install setup for System76 Lemur Pro (lemp10) on Manjaro/Arch.
# Run as root after first boot:  sudo bash system76-setup.bash
set -euo pipefail

die() { echo "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIFI_CONF="${SCRIPT_DIR}/../lemur-pro-wifi-hack.conf"

#
# Preflight
#
[[ $EUID -eq 0 ]] || die "Must be root."
command -v paru &>/dev/null || die "'paru' not found"

[ -n "${SUDO_USER-}" ] || die \
  "Run via sudo, not directly as root (need \$SUDO_USER)"
id "$SUDO_USER" &>/dev/null || die "User '$SUDO_USER' not found"

[ -f "$WIFI_CONF" ] || die "WiFi conf not found at $WIFI_CONF"

#
# Install System76 AUR packages
#
echo "Installing System76 packages..."
sudo -u "$SUDO_USER" paru -S --noconfirm \
  system76-acpi-dkms \
  system76-power \
  system76-firmware-daemon

systemctl enable --now com.system76.PowerDaemon
systemctl enable --now system76-firmware-daemon

#
# Deploy WiFi hack conf
#
echo "Deploying WiFi modprobe conf..."
cp "$WIFI_CONF" /etc/modprobe.d/iwlwifi-disable-11ax.conf
echo "Reloading iwlwifi..."
modprobe -r iwlwifi && modprobe iwlwifi && echo "iwlwifi reloaded OK" \
  || echo "WARNING: iwlwifi reload failed — reboot to apply WiFi conf"

#
# Done
#
echo
echo "Done. Verify with:"
echo "  dkms status"
echo "  systemctl is-active system76-power system76-firmware-daemon"
echo "  cat /etc/modprobe.d/iwl.conf"
echo
echo "You should reboot now."
