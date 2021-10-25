#!/bin/sh
set -e

PKGMAN=$(./package-manager.sh)
if [ "$PKGMAN" = "" ]; then
    echo "Unknown package manager."
    exit 1
fi

# If the package manager is brew, we may need to install brew
if [ "$PKGMAN" == "brew" ] && ! brew -v ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# CentOS has a frankly ANCIENT mercurial installation
if [ "$PKGMAN" = "yum" ]; then
sudo sh -c 'cat > /etc/yum.repos.d/mercurial.repo' <<- EOM
[mercurial]
name=Mercurial packages for CentOS7
# baseurl
baseurl=https://www.mercurial-scm.org/release/centos\$releasever
skip_if_unavailable=True
enabled=1
gpgcheck=0
EOM
fi

# These packages don't exist on WSL
LINUX_TOOLS_PACKAGES=
if ! uname -r | grep "Microsoft"; then
	LINUX_TOOLS_PACKAGES="linux-tools-$(uname -r) linux-cloud-tools-$(uname -r)"
fi

if [ "$TRY_PACKAGES" != "" ]; then 
    PACKAGES=$(cat basic-packages | grep -v "#" | sed -E 's/ *\|.*$//g')
else
    PACKAGES=$(cat basic-packages | grep $PKGMAN | sed -E 's/ *\|.*$//g')
fi

#SHARED_PACKAGES="git wget curl tmux screen python-pip mercurial gdb binutils gcc make cmake nano zip valgrind openvpn xclip"
#APT_RPM_PACKAGES="openssh-server"
#DUMB_PACKAGES="ddate lolcat cmatrix cowsay toilet espeak"
#APT_PACKAGES="$SHARED_PACKAGES $APT_RPM_PACKAGES g++ apt-file linux-tools-common $LINUX_TOOLS_PACKAGES build-essential tweak apcalc htop auditd mercurial-keyring resolvconf trash $DUMB_PACKAGES"
#RPM_PACKAGES="$APT_RPM_PACKAGES p7zip-plugins perf"
#YUM_PACKAGES="$SHARED_PACKAGES $RPM_PACKAGES p7zip-full epel-release"
#DNF_PACKAGES="$SHARED_PACKAGES $RPM_PACKAGES p7zip"
#PACMAN_PACKAGES="$SHARED_PACKAGES openssh"

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
    sudo $PKGMAN -Syy --noconfirm
    sudo $PKGMAN -S --noconfirm $PACKAGES
elif [ "$PKGMAN" = "brew" ]; then
    $PKGMAN install $PACKAGES
else
    echo "$PKGMAN-based distros aren't supported."
    exit 1
fi

# Set up Fedora SSH server
if [ "$PKGMAN" = "dnf" ] || [ "$PKGMAN" = "yum" ]; then
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service
fi

#pip install --upgrade pip
#pip install --user mercurial_keyring

git lfs install

if which alacritty ; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(which alacritty)" 50
fi

mkdir "$HOME/bin"
cd "$HOME/bin"

# Install user apps
curl https://getmic.ro | bash


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

