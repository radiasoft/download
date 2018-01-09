#!/bin/bash
#
# Install important rpms
#
redhat_base_main() {
    if [[ ! -e /etc/fedora-release && ! -e /etc/yum.repos.d/epel.repo ]]; then
        yum --color=never --enablerepo=extras install -y -q epel-release
    fi
    local x=(
        bind-utils
        biosdevname
        bzip2
        bzip2-devel
        emacs-nox
        gcc
        gcc-c++
        gd-devel
        gdb
        ghostscript
        git
        grep
        gsl-devel
        hostname
        iproute
        iputils
        libpng-devel
        lsof
        make
        openssl-devel
        patch
        pkgconfig
        procps-ng
        readline-devel
        redhat-rpm-config
        rpm-build
        rsync
        screen
        sqlite-devel
        tar
        tk-devel
        unzip
        wget
        xz-devel
        yum-utils
        zip
        zlib-devel
    )
    if [[ ! -e /.dockerenv ]]; then
        x+=(
            lvm2
            strace
            # for ssh x11 forwarding
            xorg-x11-xauth
        )
    fi
    install_yum_install "${x[@]}"
}

redhat_base_main "${install_extra_args[@]}"
