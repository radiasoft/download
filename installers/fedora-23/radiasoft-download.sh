#!/bin/bash
#
# To run: curl radia.run | bash -s fedora-23
#
fedora_23_create_vagrant() {
    if (( $UID != 0 )); then
        echo 'must be run as root'
        return 1
    fi
    if [[ -r ~vagrant/.ssh/authorized_keys ]]; then
        return 0
    fi
    if id fedora >& /dev/null; then
        if [[ ! -r ~fedora/.ssh/authorized_keys ]]; then
            echo 'no authorized keys for user fedora'
            return 1
        fi
        cat ~fedora/.ssh/authorized_keys > ~root/.ssh/authorized_keys
        if ! userdel -r fedora >& /dev/null; then
            echo 'relogin as root@'
            return 1
        fi
    fi
    echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rs-vagrant
    chmod 400 /etc/sudoers.d/rs-vagrant
    if ! id vagrant >& /dev/null; then
        groupadd -g 1000 vagrant
        useradd -m -g vagrant -u 1000 vagrant
    fi
    if [[ ! -r ~vagrant/.ssh/authorized_keys ]]; then
        mkdir -p ~vagrant/.ssh
        cat ~root/.ssh/authorized_keys > ~vagrant/.ssh/authorized_keys
        chown -R vagrant: ~vagrant/.ssh
        chmod -R og-rwx ~vagrant/.ssh
    fi
}

fedora_23_rpms() {
    dnf update -y
    local x=(
        bind-utils
        biosdevname
        bzip2-devel
        cmake
        emacs-nox
        gcc
        gcc-c++
        gd-devel
        ghostscript
        git
        gsl-devel
        hostname
        hostname
        iproute
        iproute
        iputils
        leafpad
        libpng-devel
        llvm-libs
        lsof
        lzma-devel
        make
        openssl-devel
        patch
        pciutils
        pkgconfig
        readline-devel
        redhat-rpm-config
        rpm-build
        scite
        screen
        sqlite-devel
        strace
        tar
        tk-devel
        wget
        xauth
        xclock
        xpdf
        xpdf
        xterm
        yum-utils
        zlib-devel
    )
    dnf install -y "${x[@]}"
    if [[ " $* " =~ ' cuda ' ]]; then
        fedora_23_rpms_cuda
    fi
}

fedora_23_rpms_cuda() {
    dnf install -y \
        http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-23.noarch.rpm \
        http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-23.noarch.rpm \
        http://developer.download.nvidia.com/compute/cuda/repos/fedora23/x86_64/cuda-repo-fedora23-8.0.61-1.x86_64.rpm
    dnf clean all
    dnf install -y kmodtool dcmtk-devel
    dnf install -y cuda
}

fedora_23_setup_vagrant() {
    sudo su - vagrant <<'EOF'
    set -ex -o pipefail
    cd
    curl radia.run | bash -s home
    . ~/.bashrc
    touch requirements.txt
    bivio_path_insert ~/.pyenv/bin 1
    . ~/.bashrc
    bivio_pyenv_2
    rm requirements.txt
    . ~/.bashrc
    pip install --upgrade pip
    pip install --upgrade setuptools==32.1.3 tox
    pyenv virtualenv py2
    pyenv global py2
    . ~/.bashrc
    mkdir ~/src/radiasoft/
    cd ~/src/radiasoft/
    gcl pykern
    cd pykern
    pip install -e .
EOF
}

fedora_23_main() {
    fedora_23_create_vagrant
    fedora_23_rpms "${install_extra_args[@]}"
    fedora_23_setup_vagrant

}

fedora_23_main
