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

Then re-run this command. This should only happen in development environments.
'
    fi
    if selinuxenabled; then
        perl -pi -e 's{(?<=^SELINUX=).*}{disabled}' /etc/selinux/config
        install_err 'Disabled selinux. You need to "vagrant reload", then re-run this installer'
    fi
    if install_os_is_fedora; then
        install_yum_install dnf-plugins-core
        dnf -q config-manager \
            --add-repo \
            https://download.docker.com/linux/fedora/docker-ce.repo
    elif install_os_is_centos_7; then
        yum-config-manager \
            --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum makecache fast
        install_yum_install yum-plugin-ovl
    elif install_os_is_rhel_compatible; then
        dnf -q config-manager \
            --add-repo \
            https://download.docker.com/linux/rhel/docker-ce.repo
    else
        install_err "installer does not support os=$install_os_release_id"
    fi
    install_yum_install docker-ce
    if [[ ${redhat_docker_no_local_setup:-} ]]; then
        return 0
    fi
    usermod -aG docker vagrant
    install -d -m 700 /etc/docker
    mkdir -p "$data"
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
    "storage-driver": "overlay2"
}
EOF2
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker
}
