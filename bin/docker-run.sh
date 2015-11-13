#!/bin/bash
#
# Docker specific code for radia-run
#
radia_run_check() {
    local x=$(docker inspect --format='{{.State.Running}}' "$docker_container" 2>/dev/null || true)
    if [[ $x == true ]]; then
        install_err "Your $docker_image container is already running."
    fi
    if [[ $x == false ]]; then
        docker rm "$docker_container" >&/dev/null
    fi
}

radia_run_main() {
    radia_run_check
    local cmd=( docker run -i )
    local display=
    #TODO(robnagler) -t doesn't seem to work quite right. Maybe -t 1?
    if [[ -t 1 ]]; then
        cmd+=( -t )
    fi
    if [[ $radia_run_x11 ]]; then
        cmd+=( -v "$HOME/.Xauthority:/home/$radia_run_guest_user/.Xauthority" --net host)
        display="DISPLAY=$DISPLAY "
    fi
    if [[ $radia_run_port ]]; then
        $cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    radia_run_prompt
    "${cmd[@]}" -v "$PWD:$radia_run_guest_dir" /radia-run "$(id -u)" "$(id -g)" "$display${radia_run_cmd:-bash}"
}
