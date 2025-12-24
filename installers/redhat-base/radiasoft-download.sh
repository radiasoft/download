#!/bin/bash
#
# Install important rpms and fixup some Red Hat distro issues
#
redhat_base_main() {
    if (( $EUID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    _redhat_base_repos
    _redhat_base_pkgs
    _redhat_base_mandb
    _redhat_base_terminfo
    _redhat_base_profile_d
}


_redhat_base_mandb() {
    # mandb takes a really long time on some installs
    declare x=/usr/bin/mandb
    if [[ ! -L $x && $(readlink "$x") != true ]]; then
        ln -s -f true "$x"
    fi
}

_redhat_base_pkgs() {
    declare x=(
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
        opendkim
        openssh-server
        openssl
        openssl-devel
        patch
        pciutils
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
    if [[ ! ${install_virt_docker:-} ]]; then
        x+=( lvm2 xorg-x11-xauth )
    fi
    if install_os_is_fedora; then
        x+=( perl-debugger direnv )
    fi
    if install_os_is_centos_7; then
        x+=( createrepo pkgconfig )
    else
        x+=( createrepo_c opendkim-tools pkgconf-pkg-config execstack )
    fi
    install_yum_install "${x[@]}"
}

_redhat_base_profile_d() {
    # POSIT: install_file_from_stdin doesn't use other install_*
    install_sudo bash -euo pipefail <<END_SUDO
$(declare -f install_file_from_stdin)
cat <<'END_CAT' | install_file_from_stdin 444 root root /etc/profile.d/rs-redhat-base.sh
: \${RADIA_RUN_SERVER:='$install_server'}
: \${install_depot_server:='$install_depot_server'}
: \${install_version_centos:='$install_version_centos'}
: \${install_version_fedora:='$install_version_fedora'}
: \${install_version_python:='$install_version_python'}
export RADIA_RUN_SERVER install_depot_server install_version_centos install_version_fedora install_version_python
END_CAT
END_SUDO
}

_redhat_base_repos() {
    install_patch_centos7_mirror
    declare x
    if install_os_is_fedora; then
        # TODO(robnagler) this is an old version of mongo
        # Use RHEL8 rpm because mongodb uses SSPL which fedora doesn't support
        install_file_from_stdin 644 root root /etc/yum.repos.d/mongodb-org-4.4.repo <<'EOF'
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
includepkgs=mongodb-org-server
EOF
    else
        install_yum_install --enablerepo=extras epel-release
    fi
    if install_os_is_almalinux && ! install_yum repolist | grep -q '^crb '; then
        # Provides packages like perl(IPC::Run) needed by moreutils (below)
        # TODO(robnagler) will break with dnf5, probably
        install_yum_repo_set_enabled crb
    fi
}

# TODO(robnagler) maybe not necessary any more? Test with clean emacs/screen install
_redhat_base_terminfo() {
    declare t=xterm-256color-screen
    if infocmp "$t" &> /dev/null; then
        return
    fi
    # emacs matches $TERM name by splitting on the first dash. screen.xterm-256color
    # is not recognized as an xterm by emacs so it was not working properly.
    # This entry is set by
    # https://github.com/biviosoftware/home-env/blob/master/bashrc.d/zz-10-base.sh
    declare s
    for s in screen.xterm-256color screen-256color; do
        # centos7 has screen-256color, not screen.xterm-256color
        if ! infocmp "$s" &> /dev/null; then
            continue
        fi
    done
    if [[ $s ]]; then
        (
            umask 022
            s="$t|make emacs recognize $t,use=$s,"
            tic /dev/stdin <<<"$s"
        )
    fi
}
