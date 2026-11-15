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
copy_config "${srcconfigdir}/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf" "hyprlock" || :
copy_config "${srcconfigdir}/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf" "hypridle" || :
copy_config "${srcconfigdir}/nanorc" "$HOME/.nanorc" "nano" || :
# niri: per-machine config.<hostname>.kdl, which includes the shared common.kdl
niri_cfg="${srcconfigdir}/niri/config.$(uname -n).kdl"
if [ ! -f "$niri_cfg" ]; then
    niri_cfg="${srcconfigdir}/niri/config.lemur-pro.kdl"
fi
copy_config "${srcconfigdir}/niri/common.kdl" "$HOME/.config/niri/common.kdl" "niri" || :
copy_config "${niri_cfg}" "$HOME/.config/niri/config.kdl" "niri" || :
copy_config "${srcconfigdir}/tmux.conf" "$HOME/.tmux.conf" "tmux" || :
copy_config "${srcconfigdir}/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc" "waybar" || :
copy_config "${srcconfigdir}/waybar/style.css" "$HOME/.config/waybar/style.css" "waybar" || :

#
# Link scripts that the compositor spawns into ~/.local/bin, which is on the
# session PATH (unlike this repo's bin/, which only bashrc adds)
#
if command -v niri >/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sfv "$(realpath "$here/../bin/alacritty-here")" "$HOME/.local/bin/alacritty-here"
fi

#
# Dark mode for apps that ask the desktop portal (Firefox, GTK4/libadwaita).
# Full DEs like COSMIC manage this themselves; bare compositors like niri don't.
#
if command -v niri >/dev/null && command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || :
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark || :
fi

#
# Copy .bashrc.d files
#
mkdir -p "$HOME/.bashrc.d"
srcbashrcdir="$here/../bashrc.d"
for srcfile in "$srcbashrcdir"/* ; do
    dstfile="$HOME/.bashrc.d/$(basename "$srcfile")"
    copy_config "$srcfile" "$dstfile" || :
done

#
# Set up bashrc
#
bashrc="$HOME/.bashrc"

if ! grep -q -e 'basics-setup' -e ".bashrc.d" "${bashrc}" 2>/dev/null ; then
    echo "Configuring bashrc"
    echo "# basics-setup" >> "${bashrc}"
    echo ". ${srcconfigdir}/bashrc" >> "${bashrc}"
else
    echo "bashrc already configured"
fi

#
# Create a folder for local binaries
#
mkdir -p "$HOME/.local/bin"
