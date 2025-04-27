#!/bin/bash
set -eo pipefail

die() { echo "$*" >&2 ; exit 1 ; }

here="$(dirname "$(realpath "$0")")"

find_binary() {
    local tries=(
        "$binary"
        "/usr/bin/$binary"
        "/bin/$binary"
        "$(which "$binary" 2>/dev/null || :)"
        "$(realpath "$binary" 2>/dev/null || :)"
    )
    for binary in "${tries[@]}"; do
        if [ -n "$binary" ] && [ -f "$binary" ] && [ -x "$binary" ]; then
            echo "$binary"
            return 0
        fi
    done
    return 1
}

should_configure() {
    local srcfile="$1"
    local dstfile="$2"
    local binary="$3"

    if [ ! -e "$srcfile" ]; then
        echo "Skipping '$dstfile' because the source file '$srcfile' is missing" >&2
        return 1
    fi

    if [ -e "$dstfile" ]; then
        echo "Skipping '$dstfile' because it exists" >&2
        return 1
    fi

    if [ -n "$binary" ]; then
        binaryfp="$(find_binary "$binary" || :)"
        if [ -z "$binaryfp" ]; then
            echo "Skipping '$dstfile' without '$binary'" >&2
            return 1
        fi
    fi

    local configdir="$(dirname "$dstfile")"
    mkdir -p "$configdir" || die "Failed to create config dir for $dstfile"

    return 0
}

copy_config() {
    local srcfile="$1"
    local dstfile="$2"
    local binary="$3"

    if should_configure "$srcfile" "$dstfile" "$binary"; then
        cp -v "$srcfile" "$dstfile"
    fi
}

#
# Set up app configs
#
srcconfigdir="$here/../config-templates"
copy_config "${srcconfigdir}/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml" "alacritty" || :
copy_config "${srcconfigdir}/calcrc" "$HOME/.calcrc" "calc" || :
copy_config "${srcconfigdir}/gdbinit" "$HOME/.gdbinit" "gdb" || :
copy_config "${srcconfigdir}/gitconfig" "$HOME/.gitconfig" "git" || :
copy_config "${srcconfigdir}/helix-config.toml" "$HOME/.config/helix/config.toml" "hx" || :
copy_config "${srcconfigdir}/nanorc" "$HOME/.nanorc" "nano" || :
copy_config "${srcconfigdir}/tmux.conf" "$HOME/.tmux.conf" "tmux" || :

#
# Set up bashrc
#
bashrc="$HOME/.bashrc"

if ! grep -Eq 'basics-setup' "${bashrc}" 2>/dev/null; then
    echo "Configuring bashrc"
    echo "# basics-setup" >> "${bashrc}"
    echo ". $(pwd)/config-templates/bashrc" >> "${bashrc}"
    echo ". $(pwd)/config-templates/aliases" >> "${bashrc}"
else
    echo "bashrc already configured"
fi

#
# Create a folder for local binaries
#
mkdir -p "$HOME/.local/bin"
