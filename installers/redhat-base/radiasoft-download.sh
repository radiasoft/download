#!/bin/bash
#
# Install important rpms and fixup some redhat distro issues
#
redhat_base_main() {
    if (( $EUID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    if [[ $install_os_release_id != fedora && ! -e /etc/yum.repos.d/epel.repo ]]; then
        yum --color=never --enablerepo=extras install -y -q epel-release
    fi
    # mandb takes a really long time on some installs
    local x=/usr/bin/mandb
    if [[ ! -L $x && $(readlink -f $x) != /usr/bin/true ]]; then
        ln -s -f true /usr/bin/mandb
    fi
    local t=xterm-256color-screen
    if [[ ! -r /usr/share/terminfo/${t::1}/$t ]]; then
        # emacs matches $TERM name by splitting on the first dash. screen.xterm-256color
        # is not recognized as an xterm by emacs so it was not working properly.
        # This entry is set by
        # https://github.com/biviosoftware/home-env/blob/master/bashrc.d/zz-10-base.sh
        install_tmp_dir
        local s
        for s in screen.xterm-256color screen-256color; do
            # centos7 has screen-256color, not screen.xterm-256color
            if [[ -r /usr/share/terminfo/${s::1}/$s ]]; then
                break
            fi
        done
        if [[ $s ]]; then
            (
                umask 022
                echo "$t|make emacs recognize $t,use=$s," > t
                tic t
            )
        fi
    fi
    # https://unix.stackexchange.com/questions/553679/set-clock-to-24-hour-format-for-all-users#comment1108480_553759
    localectl set-locale C.UTF-8
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
        jq
        libffi-devel
        libpng-devel
        lshw
        lsof
        make
        nginx
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
    if [[ ! -e /.dockerenv ]]; then
        x+=(
            lvm2
            # for ssh x11 forwarding
            xorg-x11-xauth
        )
    fi
    install_yum_install "${x[@]}"
}
