#!/bin/bash

bin_dir="$HOME/bin"
sys_bin_dir='/usr/local/bin'

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

# Some files need to be installed in a "system" directory that's
# on the sudo path by default because they need root permissions.
system_files_to_install=(
    'easymkfs'
)

files_to_install=(
    'delds'
    'dia'
    'dir'
    'dirdiff.py'
    'flattendir.bash'
    'getmacaddr'
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

remove_extension() {
    echo "${1%%.*}"
}

_install() {
    local as_sudo
    local into_dir
    local file_to_install

    case "$#" in
        2) ;;
        3)
            if [ "$1" != 'sudo' ]
            then
                echo "fatal: bad install argument: with 3 args, first arg must be 'sudo'" >&2
                exit 1
            fi
            as_sudo=sudo
            shift
            ;;
        *) echo "fatal: bad install arguments: $*" >&2; exit 1;;
    esac

    into_dir="$1"
    file_to_install="$2"

    # linked_file -> targeted_file
    # We need to take the path relative to where we're going. This prevents problems with mounted filesystems
    # where what we think is "definitely undeniably root of fs" is not actually root of fs.
    local targeted_file="$(realpath --relative-to "$into_dir" -- "${script_dir}/${file_to_install}")"
    local linked_file="${into_dir}/$(remove_extension "$file_to_install")"

    # Intentional unquoting here - unquoted forms allow expanding to "no argument" instead of an empty string argument
    $as_sudo ln -s $verbose $overwrite -T "$targeted_file" "$linked_file"
}

install_file() {
    _install "$@"
}

sudo_install_file() {
    _install sudo "$@"
}

mkdir --parents -- "$bin_dir"

for f in "${files_to_install[@]}"
do
    install_file "$bin_dir" "$f"
done

# Install "system" binaries
mkdir --parents -- "$sys_bin_dir"

for f in "${system_files_to_install[@]}"
do
    sudo_install_file "$sys_bin_dir" "$f"
done

