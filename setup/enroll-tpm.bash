#!/bin/bash
set -euo pipefail

die() { echo "$*" >&2 ; exit 1 ; }

# Check for a TPM
[ -d /sys/class/tpm/tpm0 ] || die "No TPM found."

# Must be superuser
[[ $EUID -eq 0 ]] || die "Must be root."

#
# Install necessary packages
#
if command -v pacman &>/dev/null; then
  pacman -S --needed tpm2-tss
elif command -v apt-get &>/dev/null; then
  apt-get install -y tpm2-tools
elif command -v dnf &>/dev/null; then
  dnf install -y tpm2-tss tpm2-tools
elif ! ldconfig -p | grep -q libtss2-esys; then
  die "TPM2 TSS library not found and no supported package manager detected."
fi

#
# Helper: resolve a crypttab device spec to a block device path
#
resolve_device() {
  local spec="$1"
  if [[ "$spec" == UUID=* ]] || [[ "$spec" == PARTUUID=* ]]; then
    blkid -l -t "$spec" -o device
  else
    echo "$spec"
  fi
}

#
# Parse crypttab, add tpm2-device=auto to entries that lack it,
# and collect those devices for enrollment
#
cp -f /etc/crypttab /etc/crypttab.old

enroll_devices=()
tmp="$(mktemp)"

while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*(#|$) ]]; then
    echo "$line"
    continue
  fi

  read -r name device password options <<< "$line"

  if [[ "$options" != *tpm2-device=auto* ]]; then
    if [[ -z "$options" || "$options" == "-" ]]; then
      options="tpm2-device=auto"
    else
      options="${options},tpm2-device=auto"
    fi
    enroll_devices+=("$device")
  fi

  printf '%s\t%s\t%s\t%s\n' "$name" "$device" "$password" "$options"
done < /etc/crypttab > "$tmp"

mv "$tmp" /etc/crypttab

#
# Enroll each device that was missing tpm2-device=auto
#
for device_spec in "${enroll_devices[@]}"; do
  dev="$(resolve_device "$device_spec")"
  [ -b "$dev" ] || die "Could not resolve device: $device_spec"
  /usr/bin/systemd-cryptenroll "$dev" --tpm2-device=auto --tpm2-pcrs=7
done

echo "Done. Now reboot."
