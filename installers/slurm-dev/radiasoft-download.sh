#!/bin/bash

_slurm_dev_nfs_server=v.radia.run

slurm_dev_main() {
    if ! grep -i fedora  /etc/redhat-release >& /dev/null; then
        if [[ $(uname) == Darwin ]]; then
            install_err 'You need to run:

radia_run vagrant-dev fedora
vssh
radia_run slurm-dev
'
        fi
        install_err 'only works on Fedora Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant, not root'
    fi
    install_yum update
    slurm_dev_nfs
    install_yum install slurm-slurmd slurm-slurmctld
    dd if=/dev/urandom bs=1 count=1024 \
        | install_sudo install -m 400 -o munge -g munge /dev/stdin /etc/munge/munge.key
    # specify 4 CPUs
    perl -pi -e 's{^NodeName=.*}{NodeName=localhost CPUs=4 State=UNKNOWN}' \
         /etc/slurm/slurm.conf
    local f
    for f in munge slurmctld slurmd; do
        install_sudo systemctl start "$f"
        install_sudo systemctl enable "$f"
    done
    pyenv global py3
    for f in pykern sirepo; do
        cd ~/src/radiasoft/"$f"
        pip install -e .
    done
}

slurm_dev_nfs() {
    if grep -s -q $_slurm_dev_nfs_server:/home/vagrant /etc/fstab; then
        return
    fi
    install_yum install nfs-utils
    if ! showmount -e "$_slurm_dev_nfs_server" >&/dev/null; then
        install_error '
on $_slurm_dev_nfs_server you need to:

dnf install -y nfs-utils
cat << EOF > /etc/exports.d/home_vagrant.exports
/home/vagrant 10.10.10.0/24(rw,root_squash,no_subtree_check,async,secure)
EOF
systemctl enable nfs-server
systemctl restart nfs-server

'
    fi
    local f
    for f in ~/src/radiasoft/{pykern,sirepo}; do
        # do not put vers=4.1 because will get "no client callback" errors
        # F29 uses v4.2 by default
        echo "$_slurm_dev_nfs_server:$f $f nfs defaults,soft,noacl,_netdev 0 0"
    done | install_sudo tee -a /etc/fstab > /dev/null
    install_sudo mount -av
}
