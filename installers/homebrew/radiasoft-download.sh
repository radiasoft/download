#!/bin/bash

homebrew_main() {
    if [[ $install_os_release_id != darwin ]]; then
        install_err "Brew is only needed on Mac OS"
    fi
    if [[ ! $(type -p git) ]]; then
        install_err 'You need to install Xcode. Run:
xcode-select --install
' 1>&2
    fi
    local d="$HOME/brew"
    if ! mkdir "$d"; then
        echo "$d already exists; homebrew is already installed" 1>&2
        return 1
    fi
    install_download https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$d"
    bivio_not_strict_cmd source "$HOME"/.bashrc
    (
        eval "$("$d"/bin/brew shellenv)"
        brew update --force --quiet
    )
}
