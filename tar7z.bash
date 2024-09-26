#!/bin/bash

readonly SCRIPT_NAME="$(basename -- "$0")"

die () {
    [ -n "$1" ] && echo "$@" >&2
    exit 1
}

usage() {
    cat <<EOF
$SCRIPT_NAME: create a .tar.7z archive of given files

usage: $SCRIPT_NAME [archive] [files...]

options:
    archive       path to resulting .tar.7z archive
    files         paths to files to add to archive
EOF
}

[ "$#" -lt 2 ] && { usage; exit 1; }

archive_file="$1"
shift

[ -d "$archive_file" ] && die "fatal: output path is a directory"

# 7z doesn't overwrite the archive file. It just adds to it. So we'll just remove it.
rm -f -- "$archive_file"

echo "archive name: $archive_file"
echo "files: $*"
exec tar cvf - "$@" | 7z a -si -t7z -- "$archive_file"

