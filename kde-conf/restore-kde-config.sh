#!/bin/bash

set -e
cd "$(dirname "$(realpath "$0")")"

targetdir="$HOME/.config"
srcdir="."

patchopts=( --normal --backup --dry-run --verbose )

while read -r patch
do
    targetfn="$(basename "$patch" .patch)"
    target="$(realpath "$targetdir/$(dirname "$patch")/$targetfn")"
    if [ ! -f "$target" ]; then
        echo "Warning: $target not created." >&2
    else
        patch "${patchopts[@]}" -i "$patch" "$target" || \
            echo "Failed to patch $target" >&2
    fi
done < <(find "$srcdir" -name "*.patch")
