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
    local cmd=( docker run -v "$PWD:$radia_run_guest_dir" )
    if [[ ! $radia_run_cmd ]]; then
        radia_run_cmd=bash
        cmd+=( -i )
        if [[ -t 1 ]]; then
            cmd+=( -t )
        fi
    fi
    if [[ $radia_run_x11 ]]; then
        if [[ ! ( $DISPLAY && -s $HOME/.Xauthority ) ]]; then
            radia_run_err '$DISPLAY or ~/.Xauthority need to be set'
        fi
        cmd+=( -v "$HOME/.Xauthority:/home/$radia_run_guest_user/.Xauthority" --net host)
        radia_run_cmd="DISPLAY=$DISPLAY $radia_run_cmd"
    fi
    if [[ $radia_run_port ]]; then
        cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    radia_run_prompt
    "${cmd[@]}" "$radia_run_image" /radia-run "$(id -u)" "$(id -g)" "$radia_run_cmd"
}
