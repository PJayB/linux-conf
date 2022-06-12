# i3 Config

Prerequisites:

* i3
* i3lock
* xss-lock
* brightnessctl
* playerctl
* picom
* gnome-keyring libsecret
* sddm
* pulseaudio pulseaudio-jack pulseaudio-bluetooth pulsemixer
* blueman
* dunst libnotify-bin
* network-manager-gnome

Animated windows through picom: https://github.com/Arian8j2/picom-jonaburg-fix

To-Do:

* theme dunst
* i3status update on media keys
* betterlockscreen x11-utils feh graphicsmagick i3lock-color (https://github.com/Raymo111/i3lock-color)

Keyring access: https://wiki.archlinux.org/title/GNOME/Keyring#Installation

To connect to Wi-Fi:

    nmtui
    nmtui-edit

To get Wi-Fi to auto-reconnect:

    nmcli device set wlp0s20f3 autoconnect yes

To bake in a Wi-Fi password without using a keyring:

    nmcli connection modify id <SSID> 802-11-wireless-security.psk \
        <Password> 802-11-wireless-security.psk-flags 0

