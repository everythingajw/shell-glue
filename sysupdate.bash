#!/bin/bash

DOTFILES_DIR="$HOME/doc/dotfiles"

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

update_section() {
    echo " > $*"
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

# Distro detection
distro=
if which lsb_release &> /dev/null
then
    case "$(lsb_release -d | cut -d $'\t' -f 2- | tr '[:upper:]' '[:lower:]')" in
        *debian*) distro='debian';;
        *gentoo*) distro='gentoo';;
        *) ;;
    esac
else
    echo "Warning: lsb_release not found. You may want to install lsb_release for distro detection." >&2
    if [ -f /etc/debian_version ]
    then
        distro='debian'
    elif [ -f /etc/gentoo-release ]
    then
        distro='gentoo'
    fi
fi

temp_files=()

cleanup() {
    local pids="$(jobs -p)"
    if [ -n "$pids" ]
    then
        kill -TERM $pids
    fi
    if [ "${#temp_files[@]}" != 0 ]; then
        rm -rf "${temp_files[@]}" > /dev/null 2>&1 || true
    fi
}

trap cleanup EXIT SIGINT

failed_commands=()
missing=()
skipped_on_wsl=()

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

section_failed() {
    # section_failed <command> <reason>
    eecho "$2"
    failed_commands+=("$1")
}

repo_has_local_changes() {
    [ "$(git -C "$1" status --porcelain | wc -l)" != 0 ]
}

is_wsl() {
    grep -i microsoft /proc/version &> /dev/null
}

do_apt() {
    # Don't try to run this on non-Debian systems
    [ "$distro" != 'debian' ] && return 0

    update_section apt

    sudo apt update
    check_fail "apt update" || return

    sudo apt upgrade
    check_fail "apt upgrade" || return
}

do_apt_kernel_headers() {
    # We need to do kernel headers because some kernel modules need them. Without the headers, the modules won't rebuild
    # properly which causes a plethora of issues that are totally not obvious, such as VirtualBox machines not booting
    # or my graphical desktop environment not starting because the nvidia module wasn't rebuilt.

    [ "$distro" != 'debian' ] && return 0

    update_section 'apt kernel headers'

    sudo apt install "linux-headers-$(uname -r)"
    check_fail "apt install kernel headers" || return  
}

do_portage() {
    # Don't try to run this on non-Gentoo systems
    [ "$distro" != 'gentoo' ] && return 0

    update_section portage

    sudo emaint --auto sync
    check_fail "emaint sync" || return

    sudo emerge --ask --verbose --update --deep --newuse @world
    check_fail "emerge @world" || return
}
        
do_opam() {
    cmd_exists opam || return

    update_section opam

    opam update
    check_fail "opam update" || return

    opam upgrade
    check_fail "opam upgrade" || return
}

do_lazygit() {
    cmd_exists lazygit || return

    update_section lazygit

    local latest_lazygit_version
    latest_lazygit_version="$(curl -s 'https://api.github.com/repos/jesseduffield/lazygit/releases/latest' | jq -r '.tag_name' | sed s/v//g)"
    local current_lazygit_version
    current_lazygit_version="$(lazygit --version | cut -d',' -f 4 | cut -d'=' -f 2)"
    [ "$latest_lazygit_version" == "$current_lazygit_version" ] && return

    local tarfile
    tarfile="$(mktemp)"
    temp_files+=("$tarfile")
    local extract_into
    extract_into="$(mktemp -d)"
    temp_files+=("$extract_into")
    curl -Lo "$tarfile" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${latest_lazygit_version}_Linux_x86_64.tar.gz"
    tar xf "$tarfile" -C "$extract_into" lazygit
    mkdir --parents -- /usr/local/bin
    sudo install "$extract_into/lazygit" -D -t /usr/local/bin
}

do_ghcup() {
    cmd_exists ghcup || return
    update_section ghcup
    ghcup upgrade
    check_fail "ghcup upgrade" || return
}

do_gem() {
    cmd_exists gem || return
    update_section gem
    sudo gem update
    check_fail "gem update" || return
}

do_rustup() {
    cmd_exists rustup || return
    update_section rustup
    rustup update stable
    check_fail "rustup update" || return
}

do_flatpak() {
    cmd_exists flatpak || return
    update_section flatpak
    flatpak update
    check_fail "flatpak update" || return
}

do_spicetify() {
    if is_wsl
    then
        skipped_on_wsl+=("spicetify")
        return
    fi

    cmd_exists spicetify || return
    update_section spicetify
    # latest version from github has `v` prefix
    local latest_version
    latest_version="$(curl -s 'https://api.github.com/repos/spicetify/cli/releases/latest' | jq -r '.tag_name' | sed s/v//g)"
    local current_version
    current_version="$(spicetify --version)"

    if [ "$current_version" != "$latest_version" ]
    then 
        # Fix permissions as per the docs: <https://spicetify.app/docs/advanced-usage/installation/#spotify-installed-from-flatpak>
        sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
        sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps
        
        spicetify update
        check_fail "spicetify update" || return

        # spicetify restore backup apply
        # check_fail "spicetify restore backup apply" || return

        # <https://spicetify.app/docs/faq/#after-spotifys-update-running-spicetify-apply-or-spicetify-update-breaks-spotify>
        spicetify backup apply
        check_fail "spicetify backup apply" || return
    fi
}

do_vim_vundle() {
    local vundle_dir="$HOME/.vim/bundle/Vundle.vim"
    if [ ! -d "$vundle_dir/.git" ]
    then
        section_failed "vim vundle" "cannot update vundle: vundle directory is not a git repository"
        return
    fi

    if repo_has_local_changes "$vundle_dir"
    then
        section_failed "vim vundle" "refusing to update vundle: repo has outstanding local changes"
        return
    fi

    git -C "$vundle_dir" pull
    check_fail "git pull vundle" || return
}

do_vim_plugins() {
    cmd_exists "vim" || return
    update_section "vim plugins"
	# set -lx SHELL (which sh)
	vim +BundleInstall! +BundleClean +qall
    check_fail "vim update" || return
}

do_shell_glue() {
    update_section "shell-glue"

    # This script is really located in the shell-glue repo. Obtain the directory where this script is, resolving all symlinks.
    local dir
    dir="$(realpath -- "${BASH_SOURCE[0]}")"
    dir="$(dirname -- "$dir")"

    # We'll play it really safe and only pull if there are no outstanding changes.
    if repo_has_local_changes "$dir"
    then
        eecho "Cannot update shell-glue. Outstanding local changes found."
        failed_commands+=("shell-glue")
        return 1
    fi
    
    # The actual update should be as simple as pulling.
    git -C "$dir" pull
    check_fail "shell-glue git pull" || return

    # Now install
    local install_script="$dir/install.sh"
    if [ ! -x "$install_script" ]
    then
        section_failed "shell-glue" "shell-glue does not have install script or it is not executable"
        return
    fi
    "$install_script" --verbose
    check_fail "shell-glue install" || return
}

do_dotfiles() {
    update_section "dotfiles"

    # We need to be in a git repo for this update to happen and we need to have the install script.
    if [ ! -d "$DOTFILES_DIR/.git" ]
    then
        section_failed "dotfiles" "dotfiles directory is not a git repository"
        return
    fi

    if repo_has_local_changes "$DOTFILES_DIR"
    then
        section_failed "dotfiles" "refusing to update dotfiles repo: outstanding local changes found"
        return
    fi

    # Fetch changes
    git -C "$DOTFILES_DIR" pull
    check_fail "dotfiles git pull" || return
    
    # Apply changes
    local install_script="$DOTFILES_DIR/install.sh"
    if [ ! -x "$install_script" ]
    then
        section_failed "dotfiles" "dotfiles directory does not have install script or it is not executable"
        return
    fi
    "$install_script"
    check_fail "dotfiles install" || return
}

do_gh_cli_keyring() {
    [ "$distro" = 'debian' ] || return 0

    update_section "gh cli keyring"

    local keyring_path
    if [ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
        keyring_path="/usr/share/keyrings/githubcli-archive-keyring.gpg"
    else
        keyring_path="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    fi

    sudo curl -Lo "$keyring_path" 'https://cli.github.com/packages/githubcli-archive-keyring.gpg'
    check_fail "curl gh gpg key" || return

    sudo chmod go+r "$keyring_path"
}

do_topgrade() {
    cmd_exists topgrade || return
    topgrade "${topgrade_args[@]}"
}

topgrade_args=(--disable containers --disable vim)

if [ "$distro" = 'debian' ]
then
    topgrade_args+=(--disable system)
    # Need to do the gh cli keyring first to avoid `apt update` giving a warning
    do_gh_cli_keyring
    do_apt
    do_apt_kernel_headers
fi

do_topgrade

# [ "$distro" = 'gentoo' ] && do_portage

# do_opam
# do_lazygit
# do_rustup
# do_flatpak
# do_spicetify
# do_vim_vundle
# do_vim_plugins
# do_shell_glue
# do_dotfiles

# do_ghcup
# do_gem

cleanup

echo

if [ "${#missing[@]}" != '0' ]
then
    eecho "The following updates were skipped due to missing commands:"
    for cmd in "${missing[@]}"
    do
        eecho " > $cmd"
    done
fi

if [ "${#skipped_on_wsl[@]}" != '0' ]
then
    eecho "The following updates were skipped on WSL:"
    for cmd in "${skipped_on_wsl[@]}"
    do
        eecho " > $cmd"
    done
fi

if [ "${#failed_commands[@]}" != '0' ]
then
    eecho "The following commands failed:"
    for cmd in "${failed_commands[@]}"
    do
        eecho " > $cmd"
    done
fi

if [ -z "$distro" ]
then
    eecho "Warning: system package manager updates not applied because the distro could not be detected"
fi

echo 'System update complete'
