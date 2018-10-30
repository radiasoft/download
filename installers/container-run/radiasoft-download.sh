#!/bin/bash
#
# To run: curl radia.run | bash -s sirepo
#
set -euo pipefail

container_run_main() {
    radia_run_assert_not_root
    if (( $# < 1 )); then
        container_run_image=$(basename "$PWD")
        if [[ ! $container_run_image =~ ^(beamsim|python2|rs4pi|sirepo)$ ]]; then
            install_usage "Please supply an install name: beamsim, python2, rs4pi, sirepo, OR <docker/image>"
        fi
    else
        container_run_image=$1
        shift
    fi
    if [[ ! $container_run_image =~ / ]]; then
        container_run_image=radiasoft/$container_run_image
    fi
    container_run_interactive=
    if [[ $container_run_image =~ ^radiasoft/(beamsim|python2)$ ]]; then
        container_run_interactive=1
    fi
    if [[ $container_run_image =~ ^radiasoft/(beamsim|python2|rs4pi)$ ]]; then
#TODO(robnagler) need to allow for beta
        install_channel=alpha
    fi
    install_info 'Installing with docker'
    local tag=$container_run_image:$install_channel
    install_info "Downloading $tag"
    # docker pull fails when image is up to date; "cat" forces non-tty output
echo FIXME
#docker pull "$tag" || true
    container_run_radia_run
}

container_run_radia_run() {
    local script=radia-run
    install_log "Creating $script"
    # POSIT: same as containers/bin/build.sh
    local guest_user=vagrant
    local guest_uid=1000
    local guest_dir=/$guest_user
    local cmd=
    local uri=
    local db=
    local daemon=
    if [[ $container_run_image =~ ^radiasoft/(sirepo|rs4pi)$ ]]; then
        db=/sirepo
        # Command needs to be absolute (see containers/bin/build-docker.sh)
        cmd='exec /home/vagrant/.radia-run/tini -- /home/vagrant/.radia-run/start'
        uri=/
        if [[ $container_run_image =~ rs4pi ]]; then
            uri=/robot
        fi
        daemon=1
        container_run_port=8000
    fi
    cat > "$script" <<EOF
#!/bin/bash
#
# Invoke docker run on $cmd
#
set -euo pipefail
radia_run_channel='$install_channel'
radia_run_cmd='$cmd'
radia_run_container=\$(id -u -n)-\$(basename '$container_run_image')
radia_run_daemon='$daemon'
radia_run_db_dir='$db'
radia_run_guest_dir='$guest_dir'
radia_run_guest_uid='$guest_uid'
radia_run_guest_user='$guest_user'
radia_run_image='$container_run_image'
radia_run_interactive='$container_run_interactive'
radia_run_port='${container_run_port:-}'
radia_run_uri='$uri'

$(declare -f install_msg install_err | sed -e 's,^install,radia_run,')
$(declare -f $(compgen -A function | grep '^radia_run_'))

radia_run_main "\$@"
EOF
    chmod +x "$script"
    local start=restart
    if [[ $container_run_interactive ]]; then
        start=start
    fi
    install_msg "To $start, enter this command in the shell:

./$script
"
    if [[ ! ${container_run_interactive:-} ]]; then
        exec "./$script"
    fi
}

################################################################
#
# radia_run_ methods are copied into radia-run script
#
################################################################

radia_run_assert_not_root() {
    if (( $(id -u) == 0 || $(id -g) == 0 )); then
        # need to repeat, because comna
        install_err 'cannot be run as root or group 0'
    fi
}

#
# Docker radia-run-* functions: See container_run_radia_run
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

#
# Common radia-run-* functions: See container_run_radia_run
# Inline here so syntax checked and easier to edit.
#
radia_run_exec() {
    local cmd=( "$@" )
    radia_run_prompt
    if [[ $radia_run_cmd ]]; then
        cmd+=( /bin/bash -c "cd; . ~/.bashrc; $radia_run_cmd" )
    fi
    if [[ $radia_run_daemon ]]; then
        "${cmd[@]}" >& radia-run.log &
    else
        "${cmd[@]}"
    fi
}

radia_run_linux_fixup() {
    local run=.radia-run-linux
    (cat <<EOF1; cat <<EOF2) > "$run"
#!/bin/bash
#
# Work around Docker not mapping user for volumes.
# Only necessary on Linux when uid is different.
# See download/installers/container-run.
#
set -euo pipefail
rd='$build_run_dir'
rh='$build_run_user_home'
ru='$build_run_uid'
rn='$build_run_user'
EOF1
# map uid & gid to run dir's uid & gid
u=$(stat -c %u "$rd")
g=$(stat -c %g "$rd")
n=$rn
# user or group different than default run_user's home
n=radia-run
if ! getent group "$g" >& /dev/null; then
    # ensure group entry exists
    groupadd -g "$g" "$n"
fi
if [[ $u == $ru ]]; then
    # only group is different, just add group to run_user
    usermod -g "$g" -d "$rh" "$rn"
    n=$rn
elif getent passwd "$u" >& /dev/null; then
    # user exists but is not run_user; modify user in place
    n=$(id -n -u "$u")
    if [[ ! " $(id -G vagrant) " =~ " $g " ]]; then
        # Might be a system account so set shell
        usermod -a -G "$g" -s /bin/bash -d "$rh" "$n"
    fi
else
    # no user so create
    useradd --no-create-home -d "$rh" -u "$u" -g "$g" "$n"
fi
# This is similar to gosu but without a dependency on it, but
# we also set the gid to the gid of the directory which might
# not be the primary gid.
exec python - "$@" <<END
# POSIT: always a command and always absolute; see containers/bin/build-docker.sh
cmd = sys.argv[1:]
# don't need other groups so this is sufficient
os.setgroups([])
os.setgid($g)
os.setuid($u)
os.environ['HOME'] = '$rh'
os.execv(cmd[0], cmd)
END
EOF2
    chmod 755 "$run"
    # Need
    echo "--user=root --entrypoint=$radia_run_guest_dir/$run"
}

radia_run_main() {
    radia_run_assert_not_root
    radia_run_check
    local image=$radia_run_image:$radia_run_channel
    radia_run_msg "Updating Docker image: $image ..."
    local res
echo FIXME
#    if ! res=$(docker pull "$image" 2>&1); then
#        radia_run_msg "$res"
#        radia_run_msg 'Update failed: Assuming network failure, continuing.'
#    fi
    local cmd=( docker run --name "$radia_run_container" -v "$PWD:$radia_run_guest_dir" )
    if [[ $radia_run_db_dir ]]; then
        cmd+=( -v "$PWD:$radia_run_db_dir" )
    fi
    if [[ $radia_run_daemon ]]; then
        cmd+=( -d )
    elif [[ ! $radia_run_cmd ]]; then
        radia_run_cmd=bash
        cmd+=( -i )
        if [[ -t 1 ]]; then
            cmd+=( -t )
        fi
    fi
    if [[ $radia_run_port ]]; then
        cmd+=( -p "$radia_run_port:$radia_run_port" )
    fi
    local uname=$(uname)
    # if linux and uid or gid is different...
    # POSIT: $radia_run_guest_uid is same as its gid
    if [[ ${uname,,} == linux
        && $(stat -c '%u %g' "$PWD") != "$radia_run_guest_uid $radia_run_guest_uid"
    ]]; then
        # fixup returns the args
        cmd+=( $(radia_run_linux_fixup) "$image" )
    else
        cmd+=( -u "$radia_run_guest_user" "$image" )
    fi
    radia_run_exec "${cmd[@]}"
}

radia_run_msg() {
    echo "$@" 1>&2
}

radia_run_prompt() {
    local stop="To stop the application container, run:

docker rm -f '$radia_run_container'"
    if [[ $radia_run_uri ]]; then
        radia_run_msg "Point your browser to:

http://127.0.0.1:$radia_run_port$radia_run_uri

$stop"
    fi

}

container_run_main ${install_extra_args[@]+"${install_extra_args[@]}"}
