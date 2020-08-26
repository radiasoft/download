#!/bin/bash
#
# To run: curl radia.run | bash -s redhat_docker
#
set -euo pipefail

redhat_docker_main() {
    local data=/srv/docker
    if (( $EUID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    if [[ -d $data ]]; then
        install_info "$data exists, so assuming docker installed"
        return
    fi
    if [[ -e /var/lib/docker ]]; then
        # This will happen on dev systems only, but a good check
        install_err '
/var/lib/docker exists:
systemctl stop docker
systemctl disable docker
rm -rf /var/lib/docker/*
umount /var/lib/docker
rmdir /var/lib/docker
perl -pi -e "s{^/var/lib/docker.*}{}" /etc/fstab
lvremove -f /dev/mapper/docker-*

Then re-run this command
'
    fi
    if selinuxenabled; then
        perl -pi -e 's{(?<=^SELINUX=).*}{disabled}' /etc/selinux/config
        install_err 'Disabled selinux. You need to "vagrant reload", then re-run this installer'
    fi
    # if vps created, remove it so is docker-docker (same as rsconf)
    if [[ -e /dev/mapper/docker-vps ]]; then
        lvremove -f /dev/mapper/docker-vps
    fi
    local vg=docker
    local lv=docker
    local mdev=/dev/mapper/$vg-$lv
    local bdev=/dev/sdb
    if [[ ! -e $mdev ]]; then
        # pv is supposed to be created by vagrant-persistent-storage,
        # but not be
        if ! fdisk -l "$bdev" >& /dev/null; then
            install_err "$mdev does not exist, cannot install docker"
        fi
        if fdisk -l "$bdev" | grep ^/dev >& /dev/null; then
            install_err "$bdev contains mounted partitions, cannot install docker"
        fi
        if pvck "$bdev"; then
            install_err "physical volume $bdev already initialized, cannot install docker"
        fi
        pvcreate "$bdev"
        vgcreate "$vg" "$bdev"
        lvcreate -l '100%VG' -n "$lv" "$vg"
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
    mkfs.xfs -f -n ftype=1 "$mdev"
    mkdir -p "$data"
    echo "$mdev $data xfs defaults 0 0" >> /etc/fstab
    mount "$data"
    install -d -m 700 /etc/docker/tls
    # rsconf.pkcli.tls is not available so have to run manually.
    # easier to include more in -config here so different syntax
    # see https://github.com/urllib3/urllib3/issues/497
    # default_days doesn't work with -x509 so have to pass days
    cd /etc/docker/tls
    openssl req -x509 -days 9999 -newkey rsa -keyout key.pem -out cert.pem -config /dev/stdin <<EOF
[req]
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
    chmod 400 cert.pem key.pem
    install -D -m 444 /dev/stdin /etc/systemd/system/docker.service.d/override.conf <<EOF2
# https://docs.docker.com/config/daemon/#troubleshoot-conflicts-between-the-daemonjson-and-startup-scripts
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF2
    # POSIT: Same as rsconf/package_data/docker/daemon.json.jinja
    install -m 400 /dev/stdin /etc/docker/daemon.json <<EOF2
{
    "data-root": "$data",
    "hosts": ["tcp://localhost.localdomain:2376", "tcp://$(hostname -f):2376", "unix://"],
    "iptables": true,
    "live-restore": true,
    "log-driver": "journald",
    "tls": true,
    "tlscacert": "/etc/docker/tls/cert.pem",
    "tlscert": "/etc/docker/tls/cert.pem",
    "tlskey": "/etc/docker/tls/key.pem",
    "tlsverify": true,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF2
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker
}
su vagrant
