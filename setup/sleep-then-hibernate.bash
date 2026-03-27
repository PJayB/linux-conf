#!/bin/bash
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

# TODO: check hibernate is actually set up

#
# Power management / sleep
#
TIMEOUT="${1-:2h}"

echo "Configuring suspend-then-hibernate ($TIMEOUT timeout)..."

mkdir -p /etc/systemd/sleep.conf.d
cat > /etc/systemd/sleep.conf.d/sleep-then-hibernate.conf <<EOF
[Sleep]
AllowSuspendThenHibernate=yes
HibernateDelaySec=$TIMEOUT
EOF

mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/sleep-then-hibernate.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
EOF

#
# Done
#
echo
echo "Done. You should reboot now."
