#!/bin/bash

bin_dir="$HOME/bin"

script_name="$(basename -- "${BASH_SOURCE[0]}")"
script_dir="$(realpath -- "${BASH_SOURCE[0]}")"
script_dir="$(dirname -- "$script_dir")"

usage() {
    cat <<EOF
$(basename -- "${BASH_SOURCE[0]}"): install files to bin directory
usage: $(basename -- "") [options]
options:
  -h, --help          show this help and exit
  -b, --bin-dir DIR   put links to binaries in directory DIR
  -n, --no-overwrite  do not overwrite existing files
  -v, --verbose       show each file being installed
  -q, --quiet         do not show each file being installed (opposite of --verbose)

Between --verbose and --quiet, the last one takes precedence.
EOF
    exit 0
}

overwrite=-f
verbose=

for opt in "$@"
do
    case "$opt" in
        -h|--help) usage;;
    esac
done

while [ "$#" -gt 0 ]
do
    case "$1" in
        -n|--no-overwrite) overwrite= ;;
        -v|--verbose) verbose=-v ;;
        -q|--quiet) verbose= ;;
        -b|--bin-dir)
            if [ "$#" -le 1 ] || [ "${2:0:1}" = '-' ]
            then
                echo "expected argument for $1"
                exit 1
            fi
            bin_dir="$2"
            shift
            ;;
        *)
            echo "invalid argument $1"
            exit 1
            ;;
    esac
    shift
done

files_to_install=(
    'delds'
    'dia'
    'dir'
    'dirdiff.py'
    'flattendir.bash'
    'md2html.bash'
    'md2pdf.bash'
    'no'
    'pdffontembed.bash'
    'sysupdate.bash'
    'updatevim.bash'
    'tar7z.bash'
    'untar7z.bash'
    'start-redis-docker.bash'
    'start-redis-podman.bash'
)

bin_name() {
    echo "$bin_dir/${1%%.*}"
}

install_file() {
    # Do not quote verbose and overwrite - unquoted forms allow them to expand to "no argument" instead of an empty string argument
    ln -s $verbose $overwrite -- "${script_dir}/$1" "$(bin_name "$1")"
}

mkdir --parents -- "$bin_dir"

for f in "${files_to_install[@]}"
do
    install_file "$f"
done

