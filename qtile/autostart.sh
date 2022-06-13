#!/bin/bash

xss-lock --transfer-sleep-lock -- i3lock --show-failed-attempts --ignore-empty-password --color=060015
picom --experimental-backends --config ~/.config/i3/picom.conf -b
variety &
blueman-applet &
nm-applet &
dunst &

