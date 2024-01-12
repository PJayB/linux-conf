#!/bin/sh
if [ ! -f /usr/bin/curl ]; then
	echo Please install curl
	exit 1
fi

if [ ! -f /etc/apt/trusted.gpg.d/microsoft.gpg ]; then
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
fi
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'

sudo apt-get update
sudo apt-get install -y microsoft-edge-stable
