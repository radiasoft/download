#!/bin/bash
#
# Install important rpms
#
redhat_base_main() {
    if [[ ! -e /etc/fedora-release && ! -e /etc/yum.repos.d/epel.repo ]]; then
        yum --color=never --enablerepo=extras install -y -q epel-release
    fi
    # mandb takes a really long time on some installs
    local x=/usr/bin/mandb
    if [[ ! -L $x && $(readlink -f $x) != /usr/bin/true ]]; then
        install_sudo ln -s -f true /usr/bin/mandb
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
        lshw
        lsof
        make
        openssl-devel
        patch
        pciutils
        pkgconfig
        procps-ng
        pxz
        readline-devel
        redhat-rpm-config
        rpm-build
        rsync
        screen
        sqlite-devel
        smartmontools
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

redhat_base_main ${install_extra_args[@]+"${install_extra_args[@]}"}
