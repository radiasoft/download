#!/bin/bash
#
# This is an include file in script created by docker.sh
#
# Start docker with port and volume. Will destroy old container if exists and
# isn't running.
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
    docker_run_check
    if [[ $docker_prompt ]]; then
        echo "$docker_prompt" 1>&2
    fi
    local tty=
    if [[ -t 0 ]]; then
        tty=-t
    fi
    docker run -i $tty --name="$docker_container" -v "$PWD":/vagrant \
        ${docker_port:+-p $docker_port:$docker_port} "$docker_image" \
        /su-vagrant "$(id -u)" "$(id -g)" "$docker_cmd"
}

docker_run_main "$@"
