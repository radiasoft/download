#!/bin/bash
#
# Installs development environment (with CUDA) on a Fedora VM
#
# To run: curl radia.run | bash -s fedora-dev
#

_fedora_dev_step_file=~/fedora_dev_step
_fedora_dev_first_step=remove_fedora

fedora_dev_create_vagrant() {
    if ! id vagrant >& /dev/null; then
        groupadd -g 1000 vagrant
        useradd -m -g vagrant -u 1000 vagrant
    fi
    #POSIT: Same file name as the Vagrant system uses
    local f=/etc/sudoers.d/vagrant-nopasswd
    if [[ ! -f $f ]]; then
        echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > "$f"
        chmod 400 "$f"
    fi
    f=~vagrant/.ssh/authorized_keys
    if [[ ! -f $f ]]; then
        mkdir -p ~vagrant/.ssh
        cat ~root/.ssh/authorized_keys > ~vagrant/.ssh/authorized_keys
        chown -R vagrant: ~vagrant/.ssh
        chmod -R og-rwx ~vagrant/.ssh
    fi
    _fedora_dev_step rpms
}

fedora_dev_cuda_rpms() {
    # Do nothing if no CUDA devices or if cuda already installed
    local n=setup_vagrant
    if [[ -z $(lspci | grep -i nvidia) || -d /usr/local/cuda/bin ]]; then
        _fedora_dev_step "$n"
        return 0
    fi
    if [[ -n $(type -t nvidia-smi) ]]; then
        if [[ ! $(nvidia-smi -L 2>&1) =~ ^GPU\ 0: ]]; then
            echo 'nvidia-smi: not returning "GPU 0:", abort' 1>&2
            nvidia-smi 1>&2
            return 1
        fi
        dnf install -y cuda
        _fedora_dev_step "$n"
        return 0
    fi
    dnf install -y \
        http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-23.noarch.rpm \
        http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-23.noarch.rpm \
        http://developer.download.nvidia.com/compute/cuda/repos/fedora23/x86_64/cuda-repo-fedora23-8.0.61-1.x86_64.rpm
    dnf clean all
    # dcmtk-devel required for rs4pi
    dnf install -y kmodtool dcmtk-devel kernel-devel
    local f=~/nvdia.run
    curl -o "$f" https://depot.radiasoft.org/foss/NVIDIA-Linux-x86_64-340.102.run
    bash "$f" --silent
    rm -f "$f"
    _fedora_dev_ask_reboot
}

fedora_dev_remove_fedora() {
    if id fedora >& /dev/null; then
        local s=~fedora/.ssh/authorized_keys
        local d=~fedora/.ssh/authorized_keys
        if [[ ! -r $s ]]; then
            echo "$s: is missing, aborting" 1>&2
            return 1
        fi
        if ! cmp -s "$s" "$d"; then
            mkdir "$(dirname "$d")"
            cat "$s" > "$d"
            chmod 400 "$d"
        fi
        if ! userdel -r fedora >& /dev/null; then
            _fedora_dev_ask_reboot
        fi
    fi
    _fedora_dev_step create_vagrant
}

fedora_dev_rpms() {
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
    _fedora_dev_step cuda_rpms
    _fedora_dev_ask_reboot
}

fedora_dev_setup_vagrant() {
    sudo su - vagrant <<EOF
    set -euo pipefail
    $(declare -f install_source_bashrc)
    cd
    curl https://depot.radiasoft.org/index.sh | bash -s home
    install_source_bashrc
    touch requirements.txt
    bivio_path_insert ~/.pyenv/bin 1
    install_source_bashrc
    bivio_pyenv_2
    rm requirements.txt
    install_source_bashrc
    pip install --upgrade pip
    pip install --upgrade setuptools==32.1.3 tox
    if ! pyenv versions | grep -s -q py2; then
        pyenv virtualenv py2
    fi
    pyenv global py2
    install_source_bashrc
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    if [[ ! -d pykern ]]; then
        gcl pykern
    fi
    cd pykern
    pip install -e .
EOF
    _fedora_dev_step stop
}

fedora_dev_stop() {
    rm -f "$_fedora_dev_step_file"
    _fedora_dev_exit=1
}

_fedora_dev_ask_reboot() {
    cat <<EOF
For the next step, please reboot and relogin as root:
reboot

Then login as root (not fedora), and rerun this command:
ssh root@<this-host>
curl radia.run | bash -s $install_repo
EOF
    _fedora_dev_exit=1
}

_fedora_dev_main() {
    if (( $UID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    _fedora_dev_step
    while true; do
        "fedora_dev_$_fedora_dev_step"
        if [[ -n $_fedora_dev_exit ]]; then
            return 0
        fi
    done
}

_fedora_dev_step() {
    if [[ -n $1 ]]; then
        _fedora_dev_step=$1
        echo "_fedora_dev_step=$_fedora_dev_step" > "$_fedora_dev_step_file"
        return 0
    fi
    if [[ ! -r $_fedora_dev_step_file ]]; then
        _fedora_dev_step "$_fedora_dev_first_step"
        return 0
    fi
    _fedora_dev_step=
    . "$_fedora_dev_step_file"
    if [[ -z $_fedora_dev_step ]]; then
        echo "$_fedora_dev_step_file: empty, aborting"
        return 1
    fi
    return 0
}

_fedora_dev_main
