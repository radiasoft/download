#!/bin/bash
#
# Install Docker image and start
#
docker_main() {
    install_info 'Installing with docker'
    local tag=$install_image:$install_docker_channel
    install_info "Downloading $tag"
    if [[ -z $install_test ]]; then
        install_exec docker pull "$tag"
    fi
    install_radia_run
}

#
# Docker radia-run-* functions: See install_radia_run
# Inline hear so syntax checked and easier to edit.
#
radia_run_check() {
    local x=$(docker inspect --format='{{.State.Running}}' "$radia_run_container" 2>/dev/null || true)
    if [[ $x == true ]]; then
        install_err "Your $radia_run_image container is already running."
    elif [[ $x == false ]]; then
        docker rm "$radia_run_container" >&/dev/null
    fi
}

radia_run_main() {
    radia_run_check
    local cmd=( docker run -v $PWD:$radia_run_guest_dir --name $radia_run_container )
    if [[ -z $radia_run_cmd ]]; then
        radia_run_cmd=bash
        cmd+=( -i )
        if [[ -t 1 ]]; then
            cmd+=( -t )
        fi
    fi
    if [[ -n $radia_run_x11 ]]; then
        if ! [[ -n $DISPLAY && -s $HOME/.Xauthority ]]; then
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
    if [[ -n $radia_run_port ]]; then
        cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    cmd+=( "$radia_run_image:$radia_run_channel" /radia-run "$(id -u)" "$(id -g)" )
    radia_run_exec "${cmd[@]}"
}
