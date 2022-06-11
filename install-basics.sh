#!/bin/bash
set -e

PKGMAN=$(./package-manager.sh)
if [ "$PKGMAN" = "" ]; then
    echo "Unknown package manager."
    exit 1
fi

# If the package manager is brew, we may need to install brew
if [ "$PKGMAN" = "brew" ] && ! brew -v ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

filters=( )

# Raspbian doesn't have some packages
is_rpi=
if which lsb_release >/dev/null && lsb_release -i | grep -q 'Raspbian'; then
    is_rpi=yes
    filters+=( "!rpi" )
fi

# WSL doesn't have some packages
is_wsl=
if uname -r | grep "Microsoft"; then
    is_wsl=yes
    filters+=( "!wsl" )
fi

filters="(^#)$(printf "|(%s)" "${filters[@]}")"

# These packages don't exist on WSL or Raspbian
LINUX_TOOLS_PACKAGES=
if [ -z "$is_rpi" ] && [ -z "$is_wsl" ]; then
	LINUX_TOOLS_PACKAGES="linux-tools-$(uname -r) linux-cloud-tools-$(uname -r)"
fi

if [ "$TRY_PACKAGES" != "" ]; then
    PACKAGES=$(cat basic-packages | grep -vE "$filters" | sed -E 's/ *\|.*$//g')
else
    PACKAGES=$(cat basic-packages | grep -vE "$filters" | grep $PKGMAN | sed -E 's/ *\|.*$//g')
fi

if [ "$PKGMAN" = "apt-get" ]; then
    sudo $PKGMAN update
    sudo $PKGMAN install -y $PACKAGES $LINUX_TOOLS_PACKAGES
elif [ "$PKGMAN" = "yum" ]; then
    sudo $PKGMAN install -y $PACKAGES
    sudo $PKGMAN groupinstall -y 'Development Tools'
elif [ "$PKGMAN" = "dnf" ]; then
    sudo $PKGMAN install -y $PACKAGES
    sudo $PKGMAN groupinstall -y 'Development Tools'
elif [ "$PKGMAN" = "pacman" ]; then
    sudo $PKGMAN -Suy --needed --noconfirm $PACKAGES
elif [ "$PKGMAN" = "brew" ]; then
    $PKGMAN install $PACKAGES
else
    echo "$PKGMAN-based distros aren't supported."
    exit 1
fi

# Set up Fedora SSH server
if [ "$PKGMAN" != "brew" ]; then
    sudo systemctl enable --now sshd.service
fi

git lfs install || :

# Emoji picker
pip3 install tuimoji || :

# Arch setup
# (disabled for now)
if false && [ "$PKGMAN" = "pacman" ]; then
    # Install yay
    yay_target="$HOME/.yay-git"
    if [ ! -d "$yay_target" ]; then
        git clone "https://aur.archlinux.org/yay-git.git" "$yay_target"
        cd "$yay_target"
        makepkg -si --needed --noconfirm || :
        cd -
    fi

    # Install yay packages that aren't installed already
    readarray -t yaypkgs < <(grep -v "$(pacman -Qqm)" yay-packages)
    if [[ ${#yaypkgs[@]} -gt 0 ]]; then
        yay -S --norebuild --noredownload --batchinstall --nocleanafter --answerclean No --answerdiff N "${yaypkgs[@]}"
    fi
fi

# Debian setup
if which update-alternatives && which alacritty ; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(which alacritty)" 50
fi

mkdir -p "$HOME/bin"
cd "$HOME/bin"

# Terminal
if which snap >/dev/null; then
	sudo snap install alacritty --classic
fi

# Set up WSL-specific stuff
if uname -r | grep "Microsoft"; then
    sudo apt-get purge -y openssh-server
    sudo apt-get install -y openssh-server
    echo "PermitRootLogin no
AllowUsers $USER
PasswordAuthentication yes
UsePrivilegeSeparation no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    sudo service ssh --full-restart
fi

echo "Done."

