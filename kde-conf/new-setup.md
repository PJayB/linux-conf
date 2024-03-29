Essentials
==========

## Install updates

    sudo pacman -Suy

## Install basics

    sudo pacman -S git curl wget nano sponge tmux

## Clone setup scripts

    git clone https://github.com/PJayB/linux-conf ~/setup-scripts
    cd ~/setup-scripts

## Set up user

    ./configure-user.sh

## Switch to Zsh

    chsh -s /bin/zsh

## Set up SSH

    sudo systemctl enable --now sshd


Optional
========

## Set up SSH keys to GitHub

    ./github-ssh-key.sh


KDE Setup
=========


## Restoring Settings

TBD

See `*.diff` for settings that should be applied.

Zsh in Konsole:

    cp Pete.profile ~/.local/share/konsole/Pete.profile
    sed 's:DefaultProfile=.*\.profile:DefaultProfile=Pete.profile:g' ~/.config/konsolerc | sponge ~/.config/konsolerc

## Bismuth

Install:

    yay -S kwin-bismuth

You'll need to apply the diffs to set this up properly.

## Things to Fix

 - [ ] Zsh ctrl+arrow keys
 - [ ] Tmux copy-paste

## Finishing up

Reload settings:

    qdbus org.kde.kwin /KWin reconfigure

## Saving Git Diffs of Settings

    ./update-kde-config.sh

Software
========

## Packages Available

    sudo pacman -S \
        bitwarden \
        synergy \
        meld \
        ;

## Look into Other Software...

* Visual Studio Code
* Nari Ultimate config
