#!/bin/bash
#
# Install important rpms and fixup some redhat distro issues
#
redhat_base_main() {
    if (( $EUID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    local x
    if [[ $install_os_release_id == fedora ]]; then
        x=/etc/yum.repos.d/mongodb-org-4.4.repo
        if [[ ! -e $x ]]; then
            # Use RHEL8 rpm because mongodb uses SSPL which fedora doesn't support
            install -m 644 /dev/stdin "$x" <<'EOF'
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
includepkgs=mongodb-org-server
EOF
        fi
    elif [[ ! -e /etc/yum.repos.d/epel.repo ]]; then
        yum --color=never --enablerepo=extras install -y -q epel-release
    fi
    # mandb takes a really long time on some installs
    x=/usr/bin/mandb
    if [[ ! -L $x && $(readlink "$x") != true ]]; then
        ln -s -f true "$x"
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
        moreutils
        nginx
        openssh-server
        openssl
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
        sysstat
        tar
        time
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
    # TODO(robnagler) generalize
    if [[ $install_os_release_id == fedora ]] && ! install_version_fedora_lt_36; then
        install_yum_install perl-debugger
    fi
    # See: git.radiasoft.org/download/issues/231
    if [[ $install_os_release_id == fedora && $install_os_release_version_id == 32 ]]; then
        install_sudo dnf module enable -y nodejs:16/default
    fi
}
