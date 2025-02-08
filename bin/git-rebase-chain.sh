#!/bin/bash
prev_branch=
flags=
reset=
dryrun=
branches=( )

while [[ $1 == -* ]]; do
    case "$1" in
    -i|--interactive) flags="$flags -i" ;;
    -r|--reset)       reset=yes ;;
    -n|--dry-run)     dryrun="echo" ;;
    esac
    shift
done

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 [-*|--git-flags] base_branch branch1 branch2 branch3..." >&2
    exit 1
fi

echo "flags: $flags"
echo "branch chain: $*"

$dryrun git fetch origin "$@"

for i in "$@"; do
    if [ -n "$i" ]; then
        $dryrun git checkout "$i"
        [ -z "$reset" ] || git reset --hard "origin/$i"
        if [ -n "$prev_branch" ]; then
            $dryrun git rebase $flags "$prev_branch" || exit 1
            branches+=( "$i" )
        fi
        prev_branch="$i"
    fi
done

echo "Push using:"
echo "  git push -f origin ${branches[*]}"
