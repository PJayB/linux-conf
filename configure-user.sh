#!/bin/bash
#set -e

mkdir -p ~/.ssh
mkdir -p ~/.config/micro
mkdir -p ~/.config/tilde
mkdir -p $HOME/.config/alacritty
mkdir -p $HOME/.config/nvim

[ -e ~/.config/nvim/init.vim ] || ln -sv $(pwd)/config-templates/init.vim ~/.config/nvim/init.vim
[ -e ~/.vimrc ] || ln -sv $(pwd)/config-templates/vimrc ~/.vimrc
[ -e ~/.calcrc ] || ln -sv $(pwd)/config-templates/calcrc ~/.calcrc
[ -e ~/.nanorc ] || ln -sv $(pwd)/config-templates/nanorc ~/.nanorc
[ -e ~/.gitconfig ] || ln -sv $(pwd)/config-templates/gitconfig ~/.gitconfig
[ -e ~/.gdbinit ] || ln -sv $(pwd)/config-templates/gdbinit ~/.gdbinit
[ -e ~/.tmux.conf ] || ln -sv $(pwd)/config-templates/tmux.conf ~/.tmux.conf
[ -e ~/.config/micro/bindings.json ] || ln -sv $(pwd)/config-templates/micro-bindings.json ~/.config/micro/bindings.json
[ -e ~/.config/micro/settings.json ] || ln -sv $(pwd)/config-templates/micro-settings.json ~/.config/micro/settings.json
[ -e ~/.config/alacritty/alacritty.yml ] || ln -sv $(pwd)/config-templates/alacritty.yml ~/.config/alacritty/alacritty.yml
[ -e ~/.config/tilde/config ] || ln -sv $(pwd)/config-templates/tilde.config ~/.config/tilde/config

#if [ "$TERM" != "cygwin" ]; then
#    sudo cp -v config-templates/lynx.cfg /etc/lynx.cfg
#fi

# nvim config
nvim_cfg="$HOME/.local/share/nvim"
nvim_plug="$nvim_cfg/site/autoload/plug.vim"
if [ ! -f "$nvim_plug" ] && which nvim; then
	sh -c "curl -fLo '${nvim_plug}' --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	nvim -c ":PlugInstall" -c ":qa"
fi

touch ~/.bashrc

if ! grep -Eq 'basics-setup' ~/.bashrc; then
    echo "Configuring bashrc"
    echo "# basics-setup" >> ~/.bashrc
    echo ". $(pwd)/config-templates/bashrc" >> ~/.bashrc
    echo ". $(pwd)/config-templates/aliases" >> ~/.bashrc
else
    echo "bashrc already configured"
fi

if ! grep -Eq 'basics-setup' ~/.zshrc; then
    echo "Configuring zshrc"
    echo "# basics-setup" >> ~/.zshrc
    echo ". $(pwd)/config-templates/zshrc" >> ~/.zshrc
    echo ". $(pwd)/config-templates/aliases" >> ~/.zshrc
else
    echo "zshrc already configured"
fi

if [ ! -f ~/.ssh/config ]; then
    echo "Don't forget to set up your ssh keys!"
fi

if [ "x$(uname -s)" = "xDarwin" ]; then
    cp -v darwin/inputrc ~/.inputrc
    cp -v darwin/nanorc ~/.nanorc
    CODEPATH="$HOME/Library/Application Support/Code/User"
else
    CODEPATH="$HOME/.config/Code/User"
fi

mkdir -vp "$CODEPATH"
cp -vnr $(pwd)/config-templates/vscode/* "$CODEPATH/"

mkdir -p "$HOME/.local/bin"
#rsync -vac "$(pwd)/tools/" "$HOME/.local/bin"

if which alacritty ; then
    update-alternatives --set x-terminal-emulator "$(which alacritty)"
fi

if [ "$SHELL" = "/bin/bash" ]; then
    . ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ]; then
    . ~/.zshrc
fi
