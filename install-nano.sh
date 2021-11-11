#!/bin/bash
set -e

nanodir="${NANOHOME:-$HOME/nano}"

if [ ! -d "$nanodir" ]; then
    mkdir -p "$nanodir"
    git clone https://git.savannah.gnu.org/git/nano.git "$nanodir"
fi

sudo apt install -y\
    autoconf \
    automake \
    autopoint \
    gcc \
    gettext \
    git \
    groff \
    make \
    pkg-config \
    texinfo \
    libncurses-dev \
    ;

cd "$nanodir"
./autogen.sh
./configure --enable-utf8
make -j "$(nproc)"

sudo apt purge -y nano || :
sudo make install

sudo update-alternatives --install \
    /usr/bin/editor \
    editor \
    /usr/local/bin/nano \
    30

sudo update-alternatives --set \
    editor \
    /usr/local/bin/nano
