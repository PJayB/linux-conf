#!/bin/bash
die() { echo "$*" ; exit 1 ; }

while getopts ":t:i:u:n:" opt ; do
    case "${opt}" in
        n)
            title="${OPTARG}"
            ;;
        u)
            username="${OPTARG}"
            ;;
        i)
            keyfile="${OPTARG}"
            ;;
        t)
            accessToken="${OPTARG}"
            ;;
        *)
            die "Unknown option: '$opt'"
            ;;
    esac
done

keyfile="${keyfile:-$HOME/.ssh/id_rsa}"
pubkeyfile="$keyfile.pub"

if [ ! -f "$pubkeyfile" ]; then
    read -p "Do you want to generate '$keyfile'? (y/n): " yn
    case "$yn" in
        y|yes|Y|Yes|YES)    ;;
        n|no|N|No|NO)       exit 0 ;;
    esac

    ssh-keygen -t rsa -f "$keyfile" || die "Failed to generate SSH key"
fi

[ -f "$pubkeyfile" ] || die "Public key missing at $pubkeyfile"

if [ -z "$username" ]; then
    read -p "Enter your GitHub username: " username
    [ -n "$username" ] || die "Can't proceed without a username"
fi

if [ -z "$accessToken" ]; then
    read -p "Enter your GitHub access token: " accessToken
    [ -n "$accessToken" ] || die "Can't proceed without an access token"
fi

if [ -z "$title" ]; then
    title="$USER@$(hostname)"
fi

keyContent="$(cat "$pubkeyfile")"

curl \
    -u "$username:$accessToken" \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/keys \
    -d '{"key": "'"$keyContent"'", "title": "'"$title"'"}' \
    || die "Failed to upload key"

# Fix this repo remote if needed
if git remote show -n origin | grep -q "https://github.com" ; then
    read -p "Do you want to set this repo to use git://? (y/n): " yn
    case "$yn" in
        y|yes|Y|Yes|YES) ;;
        *)               exit 0 ;;
    esac
    git remote rm origin
    git remote add origin git@github.com:PJayB/linux-conf.git
fi
