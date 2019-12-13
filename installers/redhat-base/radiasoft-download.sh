#!/bin/bash
#
# Install important rpms and fixup some redhat distro issues
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
    if [[ ! -r /usr/share/terminfo/x/xterm-256color-screen ]]; then
        # emacs matches $TERM name by splitting on the first dash. screen.xterm-256color
        # is not recognized as an xterm by emacs so it was not working properly.
        # This entry is set by
        # https://github.com/biviosoftware/home-env/blob/master/bashrc.d/zz-10-base.sh
        (
            umask 022
            echo 'xterm-256color-screen|needed for emacs to recognize screen.xterm-256color,use=screen.xterm-256color,' | tic /dev/stdin
        )
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
