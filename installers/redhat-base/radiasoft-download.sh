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
        readline-devel
        redhat-rpm-config
        rpm-build
        screen
        sqlite-devel
        strace
        tar
        tk-devel
        unzip
        wget
        xz-devel
        yum-utils
        zip
        zlib-devel
    )
    install_yum_install "${x[@]}"
}

redhat_base_main "${install_extra_args[@]}"
