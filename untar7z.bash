#!/bin/bash

readonly SCRIPT_NAME="$(basename -- "$0")"
die () {
    [ -n "$1" ] && echo "$@" >&2
    exit 1
}

usage() {
    cat <<EOF
$SCRIPT_NAME: extract all files from a .tar.7z archive

usage: $SCRIPT_NAME [archive]

options:
    archive     the name of the .tar.7z archive to extract
EOF
}

[ "$#" != 1 ] && { usage; exit 1; }

archive_file="$1"

exec 7z e -so -- "$archive_file" | tar xvf -

