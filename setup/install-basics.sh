#!/bin/bash
set -eo pipefail

package_manager() {
  if [ "$(uname -s)" == "Darwin" ]; then
      echo "brew"
  else
      declare -A osInfo;
      osInfo[/usr/bin/rpm-ostree]=rpm-ostree
      osInfo[/etc/redhat-release]=yum
      osInfo[/etc/arch-release]=pacman
      osInfo[/etc/gentoo-release]=emerge
      osInfo[/etc/SuSE-release]=zypp
      osInfo[/etc/debian_version]=apt-get
      osInfo[/etc/fedora-release]=dnf

      packageMgr=
      for f in ${!osInfo[@]}
      do
          if [[ -f $f ]];then
              packageMgr=${osInfo[$f]}
              break
          fi
      done
      echo $packageMgr
  fi
}

PACKAGELIST="${1:-basic-packages}"

PKGMAN=$(package_manager)
if [ "$PKGMAN" = "" ]; then
    echo "Unknown package manager."
    exit 1
fi

# If the package manager is brew, we may need to install brew
if [ "$PKGMAN" = "brew" ] && ! brew -v ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

filters=( )

# ARM doesn't have some packages
if uname -m | grep -q 'aarch64'; then
    filters+=( "!arm" )
fi

# Raspbian doesn't have some packages
if lsb_release -i 2>/dev/null | grep -q 'Raspbian'; then
    filters+=( "!rpi" )
fi

# WSL doesn't have some packages
if uname -r | grep -i "Microsoft"; then
  filters+=( "!wsl" )
fi

# Only install gui apps on syskems with xorg on it
if [ ! -e "/usr/bin/Xorg" ] && [ -z "$DISPLAY" ]; then
  filters+=('&xorg')
fi

if [ -z "${filters[*]}" ]; then
  filters="^#"
else
  filters="(^#)$(printf "|(%s)" "${filters[@]}")"
fi

readarray -t PACKAGES < <(grep "$PKGMAN" "${PACKAGELIST}" |
  grep -vE "$filters" | cut -d' ' -f1)

if [ "$PKGMAN" = "apt-get" ]; then
    sudo $PKGMAN install -y "${PACKAGES[@]}"
elif [ "$PKGMAN" = "yum" ]; then
    sudo $PKGMAN install -y "${PACKAGES[@]}"
    sudo $PKGMAN groupinstall -y 'Development Tools'
elif [ "$PKGMAN" = "dnf" ]; then
    sudo $PKGMAN install -y "${PACKAGES[@]}"
    sudo $PKGMAN groupinstall -y 'Development Tools'
elif [ "$PKGMAN" = "pacman" ]; then
    sudo $PKGMAN -Suy --needed --noconfirm "${PACKAGES[@]}"
elif [ "$PKGMAN" = "brew" ]; then
    $PKGMAN install "${PACKAGES[@]}"
elif [ "$PKGMAN" = "rpm-ostree" ]; then
    "$PKGMAN" install --apply-live --idempotent --assumeyes "${PACKAGES[@]}"
else
    echo "Can't auto-install for $PKGMAN-based distros. Would install:" >&2
    for i in "${PACKAGES[@]}" ; do
        echo "  $i"
    done
    exit 1
fi
