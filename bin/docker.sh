#!/bin/bash
#
# Install Docker image and start
#
docker_main() {
    install_info 'Installing with docker'
    #TODO(robnagler) add install_channel
    install_info "Downloading $install_image"
    if [[ ! $install_test ]]; then
        install_exec docker pull "$install_image"
    fi
    install_radia_run
}

docker_main
