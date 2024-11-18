#!/bin/bash
set -euo pipefail

redhat_docker_install_main() {
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
}
