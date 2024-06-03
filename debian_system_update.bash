#!/bin/bash

usage() {
    cat <<EOF
usage: $0 [options]

options:
    -h, --help     show this help and exit
    -y, --yes      assume yes on all queries
EOF
}

eecho() {
    echo "$@" >&2
}

eprintf() {
    printf "$@" >&2
}

qgrep() {
    grep --quiet "$@" > /dev/null 2>&1
}

has_cmd() {
    which "$@" > /dev/null 2>&1
}

assume_yes='f'

while [ "$#" != '0' ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -y|--yes)
            assume_yes='t'
            ;;
    esac
    shift
done

if ! cat /etc/os-release | grep -Pe '^NAME=' | qgrep -Pie 'debian'; then
    eecho "fatal: system does not appear to be Debian"
    exit 1
fi

temp_files=()

cleanup() {
    if [ "${#temp_files[@]}" != 0 ]; then
        rm -rf "${temp_files[@]}" > /dev/null 2>&1 || true
    fi
}

trap cleanup EXIT

failed_commands=()
missing=()

cmd_exists() {
    if ! has_cmd "$1"; then
        missing+=("$1")
        return 1
    fi
    return 0
}

check_fail() {
    if [ "$?" != '0' ]; then
        failed_commands+=("$1")
        return 1
    fi
    return 0
}

do_apt() {
    sudo apt update
    check_fail "apt update" || return

    sudo apt upgrade
    check_fail "apt upgrade" || return
}
        
do_opam() {
    cmd_exists opam || return

    opam update
    check_fail "opam update" || return

    opam upgrade
    check_fail "opam upgrade" || return
}

do_lazygit() {
    cmd_exists lazygit || return
    local latest_lazygit_version="$(curl -s 'https://api.github.com/repos/jesseduffield/lazygit/releases/latest' | grep -Po '"tag_name": "v\K[^"]*')"
    local current_lazygit_version="$(lazygit --version | cut -d',' -f 4 | cut -d'=' -f 2)"
    [ "$latest_lazygit_version" == "$current_lazygit_version" ] && return

    local tarfile="$(mktemp)"
    temp_files+=("$tarfile")
    local extract_into="$(mktemp -d)"
    temp_files+=("$extract_into")
    curl -Lo "$tarfile" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${latest_lazygit_version}_Linux_x86_64.tar.gz"
    tar xf "$tarfile" -C "$extract_into" lazygit
    sudo install "$extract_into/lazygit" /usr/local/bin
}

do_ghcup() {
    cmd_exists ghcup || return
    ghcup upgrade
    check_fail "ghcup upgrade" || return
}

do_gem() {
    cmd_exists gem || return
    sudo gem update
    check_fail "gem update" || return
}

do_rustup() {
    cmd_exists rustup || return
    rustup update stable
    check_fail "rustup update" || return
}

do_flatpak() {
    cmd_exists flatpak || return
    flatpak update
    check_fail "flatpak update" || return
}

do_spicetify() {
    cmd_exists spicetify || return
    # latest version from github has `v` prefix
    local latest_version="$(curl -s 'https://api.github.com/repos/spicetify/cli/releases/latest' | jq -r '.tag_name' | sed s/v//g)"
    local current_version="$(spicetify --version)"

    if [ "$current_version" != "$latest_version" ]
    then 
        spicetify update
        check_fail "spicetify update" || return

        spicetify restore backup apply
        check_fail "spicetify restore backup apply" || return
    fi
}

do_apt
do_opam
do_lazygit
do_rustup
do_flatpak
do_spicetify

# do_ghcup
# do_gem

cleanup

if [ "${#missing[@]}" != '0' ]; then
    eecho "The following updates were skipped due to missing commands:"
    for cmd in "${missing[@]}"; do
        eecho " > $cmd"
    done
fi

if [ "${#failed_commands[@]}" != '0' ]; then
    eecho "The following commands failed:"
    for cmd in "${failed_commands[@]}"; do
        eecho " > $cmd"
    done
fi

echo 'System update complete'

