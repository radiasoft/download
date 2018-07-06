#!/bin/bash
#
# To run: curl radia.run | bash -s sirepo-dev
#
#TODO(robnagler) make sure git pull works on ~/src/biviosoftware/home-env pykern sirepo

sirepo_dev_docker() {
    if [[ -f /var/lib/docker ]]; then
        return
    fi
    if [[ ! -e /dev/mapper/docker-vps ]]; then
        install_info '/dev/mapper/docker-vps does not exist, cannot install docker'
        return
    fi
    install_sudo bash <<'EOF'
    set -euo pipefail
    dnf -y -q install dnf-plugins-core
    dnf -q config-manager \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo
    dnf -q -y install docker-ce
    usermod -aG docker vagrant
    install -d -m 700 /etc/docker
    mkfs.xfs -f -n ftype=1 /dev/mapper/docker-vps
    mkdir /var/lib/docker
    echo '/dev/mapper/docker-vps /var/lib/docker xfs defaults 0 0' >> /etc/fstab
    mount /var/lib/docker
    install -m 400 /dev/stdin /etc/docker/daemon.json <<'EOF2'
{
    "iptables": true,
    "live-restore": true,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF2
    systemctl start docker
    systemctl enable docker
EOF
}

sirepo_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    set +e
    . ~/.bashrc
    set -e
    if ! [[ $(type -t pyenv) && $(pyenv version-name) == py2 ]]; then
        bivio_pyenv_2
        set +e
        . ~/.bashrc
        set -e
    fi
    if ! rpm -q SDDSPython >& /dev/null; then
        install_repo_eval code common
    fi
    sirepo_dev_docker
    if ! type elegant >& /dev/null; then
        install_repo_eval code elegant
    fi
    if ! python -c 'import warp' >& /dev/null; then
        install_repo_eval code warp
    fi
    if ! python -c 'import srwlib' >& /dev/null; then
        install_repo_eval code srw
    fi
    if ! type rslinac >& /dev/null; then
        install_repo_eval code rslinac
    fi
    if ! python -c 'import Shadow' >& /dev/null; then
        install_repo_eval code shadow3
    fi
    if ! python -c 'import rsbeams' >& /dev/null; then
        install_repo_eval code rsbeams
    fi
    cd ~/src/radiasoft
    local p
    for p in pykern sirepo; do
        pip uninstall -y "$p" >& /dev/null || true
        if [[ -d $p ]]; then
            cd "$p"
            git pull
        else
            gcl "$p"
            cd "$p"
        fi
        if [[ -r requirements.txt ]]; then
            pip install -r requirements.txt >& /dev/null
        fi
        pip install -e .
        cd ..
    done
}

sirepo_dev_main "${install_extra_args[@]}"
