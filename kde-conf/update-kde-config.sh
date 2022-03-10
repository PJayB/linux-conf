#!/bin/bash

set -e
cd "$(dirname "$(realpath "$0")")"

srcdir="$HOME/config-backup/.config"
if [ ! -d "$srcdir" ]; then
    echo "Please copy your .config folder into $srcdir first" >&2
    exit 1
fi

basedir="$HOME/.config"

for i in ksmserverrc kglobalshortcutsrc kwinrc khotkeysrc latte/Dr460nized.layout.latte
do
    mkdir -p "$(dirname "$i")"
    diff "$srcdir/$i" "$basedir/$i" > "./$i.diff" || :
done

konsolerc() {
    grep -vE -e "^DP-[0-9]+" -e "^RestorePositionForNextInstance=" -e "^State=" "$1"
}

diff <(konsolerc "$srcdir/konsolerc") <(konsolerc "$basedir/konsolerc") > "konsolerc.diff" || :

cp ~/.local/share/konsole/Pete.profile .
