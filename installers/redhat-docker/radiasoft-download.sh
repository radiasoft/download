#!/bin/bash
#
# To run: curl radia.run | bash -s redhat_docker
#
set -euo pipefail

redhat_docker_main() {
    local data=/var/lib/docker
    if [[ -f $data ]]; then
        install_info "$data exists, so assuming docker installed"
        return
    fi
    if selinuxenabled; then
        install_sudo perl -pi -e 's{(?<=^SELINUX=).*}{disabled}' /etc/selinux/config
        install_err 'Disabled selinux. You need to "vagrant reload", then re-run this installer'
    fi
    local vg=docker
    # vps is supposed to be created by vagrant-persistent-storage
    # but isn't on Fedora 27.
    local lv=vps
    local mdev=/dev/mapper/$vg-$lv
    if [[ ! -e $mdev ]]; then
        local bdev=/dev/sdb
        if ! install_sudo fdisk -l "$bdev" >& /dev/null; then
            install_info "$mdev does not exist, cannot install docker"
            return
        fi
        if install_sudo fdisk -l "$bdev" | grep ^/dev >& /dev/null; then
            install_info "$bdev contains mounted partisions, cannot install docker"
            return
        fi
        install_sudo bash <<EOF
        set -euo pipefail
        pvcreate '$bdev'
        vgcreate '$vg' '$bdev'
        lvcreate -l 100%VG -n '$lv' '$vg'
EOF
    fi
    install_tmp_dir
    install_url radiasoft/download installers/rpm-code
    # rsconf.pkcli.tls is not available so have to run manually.
    # easier to include more in -config here so different syntax
    # see https://github.com/urllib3/urllib3/issues/497
    openssl req -x509 -newkey rsa -keyout key.pem -out cert.pem -config /dev/stdin <<EOF
[req]
default_days = 9999
default_md = sha256
distinguished_name = subj
encrypt_key = no
prompt = no
serial = $(date +%s)
x509_extensions = v3_req

[v3_req]
subjectAltName = DNS:$(hostname -f), DNS:localhost.localdomain

[subj]
CN = $(hostname -f)
EOF
    local tmp_d=$PWD
    install_sudo bash <<EOF
    set -euo pipefail
    if [[ '${install_debug:-}' ]]; then
        set -x
    fi
    if type dnf >& /dev/null; then
        dnf -y -q install dnf-plugins-core
        dnf -q config-manager \
            --add-repo \
            https://download.docker.com/linux/fedora/docker-ce.repo
        dnf -y -q install docker-ce
    else
        yum-config-manager \
            --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum makecache fast
        yum -y -q install yum-plugin-ovl
        yum -y -q install docker-ce
    fi
    usermod -aG docker vagrant
    install -d -m 700 /etc/docker
    mkfs.xfs -f -n ftype=1 '$mdev'
    mkdir -p '$data'
    echo '$mdev $data xfs defaults 0 0' >> /etc/fstab
    mount '$data'
    install -d -m 700 /etc/docker/tls
    install -m 400 "$tmp_d/cert.pem" "$tmp_d/key.pem" /etc/docker/tls
    install -D -m 400 /dev/stdin /etc/systemd/system/docker.service.d/override.conf <<'EOF2'
# https://docs.docker.com/config/daemon/#troubleshoot-conflicts-between-the-daemonjson-and-startup-scripts
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF2
    install -m 400 /dev/stdin /etc/docker/daemon.json <<'EOF2'
{
    "hosts": ["tcp://localhost.localdomain:2376", "unix://"],
    "iptables": true,
    "live-restore": true,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "tls": true,
    "tlscacert": "/etc/docker/tls/cert.pem",
    "tlscert": "/etc/docker/tls/cert.pem",
    "tlskey": "/etc/docker/tls/key.pem",
    "tlsverify": true
}
EOF2
    systemctl start docker
    systemctl enable docker
EOF
}

redhat_docker_main "${install_extra_args[@]}"
