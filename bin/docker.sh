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
        radia_run_msg 'Server is running; stopping'
        local res
        if ! res=$(docker rm -f "$radia_run_container" 2>&1); then
            radia_run_msg "$res"
            radia_run_msg 'Failed to stop, trying to start anyway.'
        fi
    elif [[ $x == false ]]; then
        docker rm "$radia_run_container" >&/dev/null || true
    fi
}

radia_run_main() {
    radia_run_check
    local image=$radia_run_image:$radia_run_channel
    radia_run_msg "Updating Docker image: $image ..."
    local res
    if ! res=$(docker pull "$image" 2>&1); then
        radia_run_msg "$res"
        radia_run_msg 'Update failed: Assuming network failure, continuing.'
    fi
    local cmd=( docker run --name $radia_run_container -v $PWD:$radia_run_guest_dir )
    if [[ -n $radia_run_db_dir ]]; then
        mkdir -p db
        cmd+=( -v "$PWD/db:$radia_run_db_dir" )
    fi
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
    if [[ -n $radia_run_port ]]; then
        cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    cmd+=( $image /radia-run "$(id -u)" "$(id -g)" )
    radia_run_exec "${cmd[@]}"
}
