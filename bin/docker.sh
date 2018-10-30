#!/bin/bash
#
# Install Docker image and start
#
docker_main() {
    install_info 'Installing with docker'
    local tag=$install_image:$install_channel
    install_info "Downloading $tag"
    if [[ -z $install_test ]]; then
        install_exec docker pull "$tag"
    fi
    install_radia_run
}
