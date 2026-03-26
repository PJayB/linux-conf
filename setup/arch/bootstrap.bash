#!/bin/bash
set -euo pipefail

die() { echo "$*" >&2 ; exit 1 ; }

usage() {
  die "$0 <block device> <hostname> <username>"
}

#
# Read a non-empty password from stdin and make sure the user got it right twice
#
read_password_verified() {
  local password_1
  local password_2
  read -s -p "Enter desired $1: " password_1
  while [ -z "$password_1" ]; do
    read -s -p "The password cannot be empty. Try again: " password_1
  done
  echo
  read -s -p "Again: " password_2
  while [[ "$password_1" != "$password_2" ]]; do
    read -s -p "That didn't match. Try again: " password_2
  done
  echo
  printf -v "$2" "$password_1"
}

#
# Start with some basic checks
#

# Must be superuser
[[ $EUID -eq 0 ]] || die "Must be root."

DISK="${1-}"
[ -n "$DISK" ] || usage
[ -e "$DISK" ] || die "Block device '$DISK' not found"
lsblk "$DISK" >/dev/null || die "'$DISK', eh? lsblk says you're a liar."

# Get hostname
NEW_HOSTNAME="${2-}"
[ -n "$NEW_HOSTNAME" ] || usage

# Get new user
NEW_USER="${3-}"
[ -n "$NEW_USER" ] || usage

# Check we're not in some weird frankenstate
[ ! -d /mnt/boot ] || die \
  "/mnt/boot exists. Are you sure you're starting clean?"

# Check we're booted in EFI mode (required for systemd-boot)
[ -d /sys/firmware/efi ] || \
  die "Not booted in EFI mode. Boot the live USB via UEFI."

#
# Get some details up front so we can verify before installing
#

# Get the kernel version from the live USB
KERNEL_PKG="$(pacman -Q linux | cut -d' ' -f1)"
[ -n "$KERNEL_PKG" ] || die "Couldn't detect current kernel package"

# Swap size
SWAPSIZE="$(awk '/MemTotal/ { print int(($2 + 1048575) / 1048576) }' \
  /proc/meminfo)"

# Detect ucode, if any
UCODE=""
if grep -qi "GenuineIntel" /proc/cpuinfo; then
  UCODE=intel-ucode
elif grep -qi "AuthenticAMD" /proc/cpuinfo; then
  UCODE=amd-ucode
fi

CRYPTSWAP_NAME=cryptswap
CRYPTSWAP="/dev/mapper/${CRYPTSWAP_NAME}"

#
# Read inputs from user
#
read_password_verified "LUKS password" LUKS_PASSWORD
read_password_verified "User password" USER_PASSWORD

[ -n "$LUKS_PASSWORD" ] || die "LUKS password required"
[ -n "$USER_PASSWORD" ] || die "User password required"

#
# Print info
#
echo "=== SUMMARY ==="
echo

echo "Creating ${SWAPSIZE}G swap partition"
echo "Creating user '$NEW_USER'"
echo "Hostname '$NEW_HOSTNAME'"
echo "Kernel: $KERNEL_PKG"
echo "ucode: $UCODE"

echo
read -n 1 -s -r -p "Press any key to continue..."
echo

#
# Function for undoing our mess
#
warn() { echo "$*" >&2 ; }

cleanup() {
  [ -z "${TMPLUKSKEY-}" ] || rm -f "$TMPLUKSKEY" || \
    warn "Failed to remove LUKS key file '$LUKSKEY'"
  [ -z "${CHROOT_ROOT-}" ] || umount -R "$CHROOT_ROOT" || \
    warn "Failed to umount '$CHROOT_ROOT'"
  [ -z "${CRYPTSWAP-}" ] || swapoff "$CRYPTSWAP" || \
    warn "Failed to turn off swap for '$CRYPTSWAP'"
  [ -z "${CRYPTSWAP_NAME-}" ] || cryptsetup close -q "$CRYPTSWAP_NAME" || \
    warn "Failed to close LUKS '$CRYPTSWAP_NAME"
  [ -z "${CRYPTROOT_NAME-}" ] || cryptsetup close -q "$CRYPTROOT_NAME" || \
    warn "Failed to close LUKS '$CRYPTROOT_NAME"
}

cleanup_error() {
  echo "An error occurred: attempting to unmount."
  cleanup
}

trap 'cleanup_error' EXIT

#
# Partition the disk
#
echo "Partitioning disk $DISK..."

SWAP_END_MIB=$((513 + SWAPSIZE * 1024))
parted --script "${DISK}" -- mklabel gpt
parted --script "${DISK}" -- mkpart ESP fat32 1MiB 513MiB
parted --script "${DISK}" -- set 1 esp on
parted --script "${DISK}" -- mkpart cryptswap 513MiB "${SWAP_END_MIB}MiB"
parted --script "${DISK}" -- mkpart cryptroot "${SWAP_END_MIB}MiB" 100%

BOOTPART="${DISK}p1"
SWAPPART="${DISK}p2"
LUKSPART="${DISK}p3"
if [ ! -e "${BOOTPART}" ]; then
  BOOTPART="${DISK}1"
  SWAPPART="${DISK}2"
  LUKSPART="${DISK}3"
fi

[ -e "${BOOTPART}" ] || die "Failed to find boot partition ${BOOTPART}"
[ -e "${SWAPPART}" ] || die "Failed to find swap partition ${SWAPPART}"
[ -e "${LUKSPART}" ] || die "Failed to find LUKS partition ${LUKSPART}"

#
# Set up LUKS
#
echo "Setting up encrypted partitions on $SWAPPART and $LUKSPART..."

CRYPTROOT_NAME=cryptroot
CRYPTROOT="/dev/mapper/${CRYPTROOT_NAME}"
TMPLUKSKEY="$(mktemp)"

#
# Set up temporary means of unlocking for the chroot script, which can't accept
# password input
#
head -c 256 /dev/urandom > "$TMPLUKSKEY"
chmod 0600 "$TMPLUKSKEY"

#
# Format both LUKS partitions with the temp key
#
cryptsetup luksFormat -q -d "$TMPLUKSKEY" "$SWAPPART"
cryptsetup luksFormat -q -d "$TMPLUKSKEY" "$LUKSPART"

#
# Add the LUKS password to both
#
echo "$LUKS_PASSWORD" | cryptsetup luksAddKey -d "$TMPLUKSKEY" "$SWAPPART"
echo "$LUKS_PASSWORD" | cryptsetup luksAddKey -d "$TMPLUKSKEY" "$LUKSPART"

#
# Open both encrypted partitions
#
cryptsetup open -d "$TMPLUKSKEY" -q "$SWAPPART" "${CRYPTSWAP_NAME}"
cryptsetup open -d "$TMPLUKSKEY" -q "$LUKSPART" "${CRYPTROOT_NAME}"

[ -e "$CRYPTSWAP" ] || die "Couldn't find $CRYPTSWAP"
[ -e "$CRYPTROOT" ] || die "Couldn't find $CRYPTROOT"

#
# No longer need the temporary key
#
cryptsetup luksRemoveKey -q "$SWAPPART" "$TMPLUKSKEY"
cryptsetup luksRemoveKey -q "$LUKSPART" "$TMPLUKSKEY"
rm -f "$TMPLUKSKEY"
unset TMPLUKSKEY

#
# Create filesystems
#
echo "Creating filesystems..."

mkfs.fat -F32 "$BOOTPART"
mkswap "$CRYPTSWAP"

SWAPFSUID="$(blkid -s UUID -o value "$CRYPTSWAP")"
[ -n "$SWAPFSUID" ] || die "Couldn't determine UUID of swap filesystem in $CRYPTSWAP"

#
# Create btrfs filesystem and subvolumes
#
mkfs.btrfs -L root "$CRYPTROOT"

mount "$CRYPTROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt

#
# Mount btrfs subvolumes for our chroot
#
CHROOT_ROOT=/mnt
CHROOT_BOOT="${CHROOT_ROOT}/boot"
BTRFS_OPTS="compress=zstd,noatime"

mount -o "subvol=@,${BTRFS_OPTS}"           "$CRYPTROOT" "$CHROOT_ROOT"
mkdir -p "${CHROOT_ROOT}"/{boot,home,var,.snapshots}
mount -o "subvol=@home,${BTRFS_OPTS}"       "$CRYPTROOT" "${CHROOT_ROOT}/home"
mount -o "subvol=@var,${BTRFS_OPTS}"        "$CRYPTROOT" "${CHROOT_ROOT}/var"
mount -o "subvol=@snapshots,${BTRFS_OPTS}"  "$CRYPTROOT" "${CHROOT_ROOT}/.snapshots"
mount -o umask=0077 "$BOOTPART" "$CHROOT_BOOT"

swapon "$CRYPTSWAP"

#
# Install some essentials
#
echo "Bootstrapping..."

basestrap "${CHROOT_ROOT}" base "$KERNEL_PKG" linux-firmware btrfs-progs \
  systemd systemd-ukify networkmanager vim nano wget curl sudo openssh rsync \
  less

#
# Conditionally install intel-ucode if running on Intel CPU
#
UCODE_INITRD_LINE=""
if [ -n "$UCODE" ]; then
  echo "Installing $UCODE..."
  basestrap "${CHROOT_ROOT}" "$UCODE"
  UCODE_INITRD_LINE="initrd  /$UCODE.img"
fi

#
# Conditionally install linux-headers if the package exists for this kernel
#
KERNEL_HEADERS_PKG="${KERNEL_PKG}-headers"
if pacman -Si "$KERNEL_HEADERS_PKG" &>/dev/null; then
  echo "Installing ${KERNEL_HEADERS_PKG}..."
  basestrap "${CHROOT_ROOT}" "$KERNEL_HEADERS_PKG"
fi

echo "Configuring..."

#
# Generate fstab
#
fstabgen -U "${CHROOT_ROOT}" >> "$CHROOT_ROOT/etc/fstab"

#
# mkinitcpio.conf: Replace HOOKS
# TODO: could probably do this more elegantly by merging the ones we want in
#
MKINITCPIOCONF="$CHROOT_ROOT/etc/mkinitcpio.conf"
[ -f "$MKINITCPIOCONF" ] || die "Couldn't find $MKINITCPIOCONF"
MKINITCPIOCONF_OLD="${MKINITCPIOCONF}.bak"
mv "$MKINITCPIOCONF" "$MKINITCPIOCONF_OLD"
NEW_HOOKS="HOOKS=(base systemd autodetect modconf block keyboard sd-vconsole sd-encrypt filesystems fsck)"
sed -r "s/^(HOOKS=.*)$/#\1\n${NEW_HOOKS}/g" "$MKINITCPIOCONF_OLD" > \
  "$MKINITCPIOCONF"

#
# Get UUID of the luks partitions (used in rd.luks.name= and crypttab)
# Note: SWAPFSUID (the swap filesystem UUID inside the LUKS container) is
# captured separately after mkswap, and used for resume= so that
# systemd-hibernate-resume can find the swap by UUID regardless of dm device
# ordering.
#
LUKSUUID="$(blkid -s UUID -o value "$LUKSPART")"
[ -n "$LUKSUUID" ] || die "Couldn't determine UUID of $LUKSPART"

SWAPUUID="$(blkid -s UUID -o value "$SWAPPART")"
[ -n "$SWAPUUID" ] || die "Couldn't determine UUID of $SWAPPART"

#
# Configure kernel entry
#
KERNEL_FILE="$(basename "$(ls "$CHROOT_BOOT"/vmlinuz-* | head -1)")"
[ -n "$KERNEL_FILE" ] || die "Could not find kernel in $CHROOT_BOOT"
INITRAMFS_FILE="$(basename "$(ls "$CHROOT_BOOT"/initramfs-* | head -1)")"
[ -n "$INITRAMFS_FILE" ] || die "Could not find initramfs in $CHROOT_BOOT"

mkdir -p "$CHROOT_BOOT/loader/entries"
{
  echo "title   Manjaro"
  echo "linux   /$KERNEL_FILE"
  [ -n "$UCODE_INITRD_LINE" ] && echo "$UCODE_INITRD_LINE"
  echo "initrd  /$INITRAMFS_FILE"
  echo "options rd.luks.name=${SWAPUUID}=${CRYPTSWAP_NAME} rd.luks.name=${LUKSUUID}=${CRYPTROOT_NAME} root=${CRYPTROOT} rootflags=subvol=@ resume=UUID=${SWAPFSUID} rw"
  echo ""
} > "$CHROOT_BOOT/loader/entries/manjaro.conf"

#
# Configure loader.conf
#
echo "default manjaro.conf
timeout 5
" > "$CHROOT_BOOT/loader/loader.conf"

#
# Enter the chroot for the next section
#
manjaro-chroot "$CHROOT_ROOT" /bin/bash <<EOF
#!/bin/bash
set -euo pipefail

die() { echo "$*" >&2 ; exit 1; }

[ -n "$LUKSPART" ] || die "LUKSPART not configured"
[ -n "$LUKSUUID" ] || die "LUKSUUID not configured"
[ -n "$CRYPTROOT_NAME" ] || die "CRYPTROOT_NAME not configured"
[ -n "$CRYPTROOT" ] || die "CRYPTROOT not configured"
[ -n "$CRYPTSWAP" ] || die "CRYPTSWAP not configured"
[ -n "$SWAPUUID"  ] || die "SWAPUUID not configured"
[ -n "$NEW_USER" ] || die "NEW_USER not configured"
[ -n "$USER_PASSWORD" ] || die "USER_PASSWORD not configured"

#
# Set up crypttab
#
mv /etc/crypttab /etc/crypttab.old || :
cat > /etc/crypttab <<CRYPTTAB_EOF
# <name> <device> <password> <options>
cryptswap UUID=${SWAPUUID} - -
cryptroot UUID=${LUKSUUID} - -
CRYPTTAB_EOF

#
# Set timezone
#
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

#
# Set locale
#
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo 'LANG="en_GB.UTF-8"' > /etc/locale.conf

#
# Set keyboard layout
#
echo "KEYMAP=us" > /etc/vconsole.conf

#
# Set hostname
#
echo "$NEW_HOSTNAME" > /etc/hostname

#
# Set systemd boot handler (not grub)
#
bootctl install

#
# Enable services
#
systemctl enable NetworkManager
systemctl enable sshd
#systemctl enable cosmic-greeter
#systemctl enable gdm

#
# Set up a user and lock root
#
useradd -m -G wheel -s /bin/bash "$NEW_USER"
echo "$USER_PASSWORD" | passwd -q -s "$NEW_USER"
passwd -l root

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/wheel

#
# Final initramfs rebuild just for good measure
#
mkinitcpio -P
EOF

#
# Copy WiFi profiles from live USB so saved networks are available on first boot
#
NM_SRC="/etc/NetworkManager/system-connections"
NM_DST="$CHROOT_ROOT/etc/NetworkManager/system-connections"
if [ -d "$NM_SRC" ] && [ -n "$(ls -A "$NM_SRC" 2>/dev/null)" ]; then
  echo "Copying WiFi profiles..."
  mkdir -p "$NM_DST"
  cp -a "$NM_SRC/." "$NM_DST/"
  chmod 700 "$NM_DST"
  chmod 600 "$NM_DST"/*
fi

#
# Health checks
#

echo "Health checks..."

# systemd-boot was installed
[ -f "$CHROOT_BOOT/EFI/BOOT/BOOTX64.EFI" ] \
  || die "FATAL: EFI fallback binary missing — bootctl install likely failed"
[ -f "$CHROOT_BOOT/EFI/systemd/systemd-bootx64.efi" ] \
  || die "FATAL: systemd-boot binary missing"

# Boot entry exists
[ -f "$CHROOT_BOOT/loader/entries/manjaro.conf" ] \
  || die "FATAL: boot entry missing"

# Kernel and initramfs are on the ESP
[ -f "$CHROOT_BOOT/$KERNEL_FILE" ] \
  || die "FATAL: kernel not found on ESP: $KERNEL_FILE"
# Check at least one non-fallback initramfs exists
ls "$CHROOT_BOOT"/initramfs-*.img 2>/dev/null | grep -qv fallback \
  || die "FATAL: no initramfs found on ESP"

# Print bootctl status for manual review
echo "--- bootctl status ---"
bootctl --esp-path="$CHROOT_BOOT" status || :
echo "--- end bootctl status ---"

#
# Done
#
trap '' EXIT
cleanup
echo "Done. You should reboot."
