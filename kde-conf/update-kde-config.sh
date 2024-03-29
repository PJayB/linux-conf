#!/bin/bash

set -e
cd "$(dirname "$(realpath "$0")")"

cp_if_exists() {
    if [ -f "$1" ]; then
        cp -v "$1" "$2"
    fi
}

srcdir="$HOME/config-backup/.config"
if [ ! -d "$srcdir" ]; then
    echo "Please copy your .config folder into $srcdir first" >&2
    exit 1
fi

basedir="$HOME/.config"

for i in ksmserverrc kglobalshortcutsrc kwinrc khotkeysrc latte/Dr460nized.layout.latte
do
    mkdir -p "$(dirname "$i")"
    diff "$srcdir/$i" "$basedir/$i" > "./$i.patch" || :
done

konsolerc() {
    grep -vE -e "^DP-[0-9]+" -e "^RestorePositionForNextInstance=" -e "^State=" "$1"
}
plasmarc() {
    grep -vE -e "^Dialog(Width|Height)=" "$1"
}

diff <(konsolerc "$srcdir/konsolerc") <(konsolerc "$basedir/konsolerc") > "konsolerc.patch" || :
diff <(plasmarc "$srcdir/plasma-org.kde.plasma.desktop-appletsrc") <(plasmarc "$basedir/plasma-org.kde.plasma.desktop-appletsrc") > "plasma-org.kde.plasma.desktop-appletsrc.patch" || :

cp_if_exists ~/.local/share/konsole/Pete.profile .

git diff || :
