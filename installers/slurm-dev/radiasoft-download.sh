#!/bin/bash

slurm_dev_main() {
    if ! grep -i fedora  /etc/redhat-release >& /dev/null; then
        install_err 'only works on Fedora Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_source_bashrc
    install_yum update
    # this may cause a reboot
    install_repo_eval redhat-docker
    install_repo_eval code common
    # rerun source, because common installs pyenv
    install_source_bashrc
    install_yum slurm-slurmd slurm-slurmctld
    dd if=/dev/urandom bs=1 count=1024 | install -m 400 -o munge -g munge /dev/stdin /etc/munge/munge.key
    local f
    for f in munge slurmctld slurmd; do
        systemctl start "$f"
        systemctl enable "$f"
    done
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    local p
    for p in pykern sirepo; do
        if [[ -d $p ]]; then
            cd "$p"
            git pull
        else
            gcl "$p"
            cd "$p"
        fi
        for v in py3; do
            pyenv global "$v"
            pip uninstall -y "$p" >& /dev/null || true
            if [[ -r requirements.txt ]]; then
                pip install -r requirements.txt >& /dev/null
            fi
            pip install -e .
        done
        # ends up with "py3" default
        cd ..
    done
    # this box should not need py2
}
