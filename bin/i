#!/bin/bash
f="$1"

set -e

listing="ls -alh --color"
open="more"
other="file"

if [ -h "$1" ]; then
    file "$1"
elif [ -z "$1" ] || [ -d "$1" ]; then
    $listing $@
elif [ -f "$1" ] && [ -r "$1" ]; then
    $open $@
elif [ -a "$1" ]; then
    $other $@
else
    echo "$1: missing?" >&2
    exit 1
fi
