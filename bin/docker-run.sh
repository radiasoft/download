#!/bin/bash
#
# Wrapper for running docker with correct user/group permissions
#

docker_run_check() {
    local x=$(docker inspect --format='{{.State.Running}}' "$docker_container" 2>/dev/null || true)
    if [[ $x == true ]]; then
        install_err "Your $docker_image container is already running."
    fi
    if [[ $x == false ]]; then
        docker rm "$docker_container"
    fi
}

docker_run_main() {
    docker_check
    if [[ $docker_prompt ]]; then
        echo "$docker_prompt"
    fi
    docker run -i -t --name="$docker_container" "$docker_image" -u vagrant \
        -v "$PWD":/vagrant \
        ${docker_port+-p $docker_port:$docker_port} \
        exec /home/vagrant/bin/docker-exec "$(id -u)" "$(id -g)" "$docker_cmd"
}

docker_run_main "$@"
