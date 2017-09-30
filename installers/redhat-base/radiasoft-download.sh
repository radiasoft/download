#!/bin/bash
#
# Install important rpms
#
redhat_base_main() {
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
        sqlite-devel
        strace
        tar
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
