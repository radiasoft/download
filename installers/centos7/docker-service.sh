#!/bin/bash
#
# Install Docker service on clean CentOS 7
#
# Usage: curl radia.run | bash -s centos7 \
#     docker-service
#
# Assumes volume group "docker" exists. Will remove all logical volumes first.
#
docker_service_main() {
    if (( $EUID != 0 )); then
        install_err 'must be run as root'
    fi
    if [[ -e /var/lib/docker ]]; then
        install_err '/var/lib/docker: already exists, unistall docker'
    fi
    yum-config-manager \
        --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum makecache fast
    yum install -y docker-ce-17.06.0.ce-1.el7.centos
    local vg=docker
    while [[ $(lvs --noheadings --nameprefixes "$vg") =~ LVM2_LV_NAME=.([^\']+) ]]; do
        lvremove -f "$vg/${BASH_REMATCH[1]}"
    done
    lvcreate --wipesignatures y -n thinpool "$vg" -l 95%VG
    lvcreate --wipesignatures y -n thinpoolmeta "$vg" -l 1%VG
    lvconvert -y \
        --zero n \
        -c 512K \
        --thinpool "$vg"/thinpool \
        --poolmetadata "$vg"/thinpoolmeta
    dd of=/etc/lvm/profile/"$vg"-thinpool.profile <<EOF
activation {
    thin_pool_autoextend_threshold=80
    thin_pool_autoextend_percent=20
}
EOF
    lvchange --metadataprofile "$vg"-thinpool "$vg"/thinpool
    lvs -o+seg_monitor
    mkdir /etc/docker
    dd of=/etc/docker/daemon.json <<EOF
{
    "iptables": false,
    "log-driver": "journald",
    "storage-driver": "devicemapper",
    "storage-opts": [
        "dm.thinpooldev=/dev/mapper/$vg-thinpool",
        "dm.use_deferred_removal=true",
        "dm.use_deferred_deletion=true"
    ]
}
EOF
    systemctl start docker
    systemctl enable docker

    # Give vagrant user access in dev mode only
    if [[ $install_channel == dev ]]; then
       usermod -aG docker vagrant
    fi
}

docker_service_main "${install_extra_args[@]}"
