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

#
# Docker radia-run-* functions: See install_radia_run
# Inline hear so syntax checked and easier to edit.
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
        cmd+=(
            -v "$HOME/.Xauthority:/home/$radia_run_guest_user/.Xauthority"
            --net host
        )
        # https://bbs.archlinux.org/viewtopic.php?id=187234
        # X Error: BadShmSeg (invalid shared segment parameter) 128
        # Qt is trying to access the X server directly
        radia_run_cmd="QT_X11_NO_MITSHM=1 DISPLAY=$DISPLAY $radia_run_cmd"
    fi
    if [[ $radia_run_port ]]; then
        cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    cmd+=( "$radia_run_image" /radia-run "$(id -u)" "$(id -g)" )
    radia_run_exec "${cmd[@]}"
}
