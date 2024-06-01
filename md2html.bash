#!/bin/bash

template_vars=()

_has_cmd() {
    which "$@" > /dev/null 2> /dev/null
}

die() {
    set +e
    [ "$#" -gt 0 ] && echo "$@" >&2
    exit 1
}

usage() {
    set +e
    cat <<EOF
usage: $(basename -- "$0") <input> <output>

options:
  input         path to input file
  output        path to output file
  -h, --help    show this usage and exit
EOF
    exit 0
}

set -e

for arg in "$@"; do
    case "$arg" in
        -h|--help) usage;;
        *) ;;
    esac
done

in_file="$1"
out_file="$2"

[ -z "$in_file" ] && die "no input file specified"
[ -z "$out_file" ] && die "no output file specified"

in_file="$(realpath -- "$in_file")"
out_file="$(realpath -- "$out_file")"


for i in "${!template_vars[@]}"; do
    template_vars[i]="--variable=${template_vars[i]}"
done

pandoc --standalone --from markdown --to html --mathml "${template_vars[@]}" -o "$out_file" -- "$in_file"

