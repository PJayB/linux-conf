#!/bin/bash
# Post-install setup for GPD Pocket 4 (AMD Ryzen AI 9 HX 370) on Manjaro/Arch.
# Run as root after first boot:  sudo bash gpd-pocket4-setup.bash
set -euo pipefail

die() { echo "$*" >&2; exit 1; }

#
# Preflight
#
[[ $EUID -eq 0 ]] || die "Must be root."
command -v paru &>/dev/null || die "'paru' not found"

[ -n "${SUDO_USER-}" ] || die \
  "Run via sudo, not directly as root (need \$SUDO_USER)"
id "$SUDO_USER" &>/dev/null || die "User '$SUDO_USER' not found"

#
# Display rotation
#
# The GPD Pocket 4 screen is physically mounted in portrait orientation.
# Without these kernel parameters, the display is sideways from first boot.
#
BOOT_ENTRY="/boot/loader/entries/manjaro.conf"
ROTATION_PARAMS="fbcon=rotate:1 video=eDP:panel_orientation=right_side_up"

echo "Configuring display rotation kernel parameters..."
[ -f "$BOOT_ENTRY" ] || die "Boot entry not found at $BOOT_ENTRY"

if grep -q "fbcon=rotate:1" "$BOOT_ENTRY"; then
  echo "  (rotation params already present — skipping)"
else
  sed -i "s|^options .*|& ${ROTATION_PARAMS}|" "$BOOT_ENTRY"
  echo "  Added: $ROTATION_PARAMS"
fi

#
# Audio fix
#
# The built-in speakers have a harsh resonance peak at ~4 kHz.
# gpd-pocket-4-pipewire installs a PipeWire DSP config that corrects this.
#
echo "Installing audio DSP fix..."
sudo -u "$SUDO_USER" paru -S --noconfirm gpd-pocket-4-pipewire

#
# Touchpad (HAILUCK CO.,LTD USB KEYBOARD Mouse)
#
# This device is a USB HID mouse emulator, not a true touchpad. On Linux it
# only emits relative pointer and scroll-wheel events — two-finger scroll and
# gestures are not possible. The best available workaround is middle-button
# scrolling: hold middle button and drag to scroll.
#
echo "Configuring touchpad (middle-button scroll)..."
mkdir -p /etc/libinput

cat > /etc/libinput/local-overrides.quirks <<'EOF'
[HAILUCK Touchpad]
MatchName=*HAILUCK*
MatchUdevType=mouse
AttrScrollButtonLock=0
ModelTabletModeNoSuspend=1
EOF

#
# Power management / sleep
#
# The AMD Ryzen AI 9 HX 370 only supports s2idle (S0ix modern standby) —
# true S3 suspend-to-RAM is not available on this hardware. s2idle drains
# battery faster than S3 would, so we configure suspend-then-hibernate:
# the system sleeps via s2idle on lid close, then auto-hibernates after 30
# minutes. The resume= kernel parameter was already set by bootstrap.bash.
#
echo "Configuring suspend-then-hibernate (30 min timeout)..."

mkdir -p /etc/systemd/sleep.conf.d
cat > /etc/systemd/sleep.conf.d/gpd-pocket4.conf <<'EOF'
[Sleep]
AllowSuspendThenHibernate=yes
HibernateDelaySec=30min
EOF

mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/gpd-pocket4.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
EOF

systemctl restart systemd-logind

#
# Done
#
echo
echo "Done. You should reboot now."
