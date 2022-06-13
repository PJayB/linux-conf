#!/bin/bash
if zenity --question --text "Log out?" --default-cancel; then
    killall qtile
fi

