# i3 Config

## Regolith

You need a newer i3 than Ubuntu probably gives you (4.22+):

> https://i3wm.org/docs/repositories.html

Install Regolith:

> https://regolith-desktop.com/docs/using-regolith/install/

Install looks, etc:

> https://regolith-desktop.com/docs/using-regolith/configuration/

I prefer `gruvbox`:

    regolith-look set gruvbox



## Old!

Prerequisites:

* i3
* i3lock
* i3status
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
* gnome-screenshot
* variety

Animated windows through picom: https://github.com/Arian8j2/picom-jonaburg-fix

Betterlockscreen: https://github.com/betterlockscreen/betterlockscreen.git
  * paru -S betterlockscreen on Arch
  * betterlockscreen x11-utils feh graphicsmagick i3lock-color (https://github.com/Raymo111/i3lock-color)
  * i3lock-color: https://github.com/Raymo111/i3lock-color

i3-layouts: https://github.com/eliep/i3-layouts
  * xdotool
  * pip install --user i3-layouts


To-Do:

* i3status update on media keys
* automatic display detection
* font for i3bar (missing glyphs for minimal install)
* pipewire support


