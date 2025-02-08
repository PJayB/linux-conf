#!/bin/bash

if ! locale -a | grep -q "en_US.utf8" ; then
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen >/dev/null
    sudo locale-gen "en_US.UTF-8"
fi

