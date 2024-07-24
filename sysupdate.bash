#!/bin/bash

unsupported() {
    echo "Error: unsupported distro $1" >&2
    exit 1
}

dir="$(realpath -- "${BASH_SOURCE[0]}")"
dir="$(dirname -- "$dir")"
distro=

if which lsb_release &> /dev/null
then
    lsb="$(lsb_release -d | cut -d $'\t' -f 2-)"
    case "${lsb,,}" in
        *debian*) distro='debian';;
        *gentoo*) distro='gentoo';;
        *) unsupported "$lsb";;
    esac
else
    echo "Warning: lsb_release not found. You may want to install lsb_release for distro detection." >&2
    if [ -f /etc/debian_version ]
    then
        distro='debian'
    elif [ -f /etc/gentoo-release ]
    then
        distro='gentoo'
    else
        unsupported
    fi
fi

case "${distro,,}" in
    debian) exec "$dir/debian_system_update.bash";;
    gentoo) exec "$dir/gentoo_system_update.bash";;
    *)
        echo "Error: unable to detect distro" >&2
        exit 1
        ;;
esac

