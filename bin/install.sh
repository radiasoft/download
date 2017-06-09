#!/bin/bash
#
# Install RadiaSoft containers
#
# TODO(robnagler):
#    - add codes.sh (so can install locally and remotely)
#    - leave in directory match? (may be overkill on automation)
#    - handle no tty case better (not working?)
#    - generalized bundling with versions
#    - add test of dynamic download and static on travis (trigger for dynamic?)
#    - tests for individual codes
#
# Testing an installer
#     download_channel=file bash ../../bin/install.sh code
set -e -o pipefail

# For error messages
install_prog='curl radia.run | bash -s'

: ${download_channel:=master}
: ${install_tmp_dir:=/var/tmp}

install_args() {
    install_debug=
    install_extra_args=()
    install_image=
    install_repo=
    install_run_interactive=
    install_type=
    install_verbose=
    : ${install_channel:=not-set}
    while [[ "$1" ]]; do
        case "$1" in
            beamsim|python2|radtrack|sirepo)
                install_image=$1
                ;;
            vagrant|docker)
                install_type=$1
                ;;
            debug)
                install_debug=1
                install_verbose=1
                ;;
            verbose)
                install_verbose=1
                ;;
            alpha|beta|dev|master|prod)
                install_channel=$1
                ;;
            quiet)
                install_verbose=
                ;;
            *)
                install_repo=$1
                shift
                install_type=repo
                install_extra_args=( $@ )
                break
                ;;
        esac
        shift
    done
    install_args_check
}

install_args_check() {
    if [[ -n $install_debug ]]; then
        set -x
    fi
    if [[ -z $install_type ]]; then
        install_type_default
    fi
    if [[ -z $install_image && -z $install_repo ]]; then
        install_image=$(basename "$PWD")
        if [[ ! $install_image =~ ^(beamsim|python2|radtrack|sirepo)$ ]]; then
            install_usage "Please supply an install name: beamsim, python2, radtrack, sirepo, OR repo name"
        fi
    fi
    case $install_type in
        repo)
            install_no_dir_check=1
            ;;
        vagrant|docker)
            if [[ $install_image == radtrack ]]; then
                install_x11=1
            fi
            if [[ $install_image =~ sirepo ]]; then
                install_port=8000
            fi
            install_image=radiasoft/$install_image
            ;;
    esac
    case $install_channel in
        dev|master)
            install_channel=dev
            install_docker_channel=latest
            install_github_channel=master
            ;;
        not-set)
            install_channel=dev
            install_docker_channel=beta
            install_github_channel=master
            ;;
        *)
            install_docker_channel=$install_channel
            install_github_channel=$install_channel
            ;;
    esac
    if [[ $install_image =~ beamsim|python2 ]]; then
        install_run_interactive=1
    fi
    install_url download bin
}

install_dir_check() {
    if [[ $install_no_dir_check ]]; then
        return
    fi
    # Loose check of our files. Just need to make sure
    # POSIT: $install_log_file contains radia-run
    if [[ $(ls -A | egrep -v '(radia-run|\.bivio_vagrant_ssh|Vagrantfile)') ]]; then
        install_err 'Current directory is not empty.
Please create a new directory, cd to it, and re-run this command.'
    fi
}

install_download() {
    local url=$1
    local no_shebang_check=$2
    local base file res
    base=$(basename "$url")
    file=$(dirname "$0")/$base
    if [[ $url == $base ]]; then
        url=$install_url/$base
    fi
    install_log curl -L -s -S "$url"
    res=$(curl -L -s -S "$url")
    if [[ -z $res || -z $no_shebang_check && ! $res =~ ^#! ]]; then
        install_err "Unable to download $url"
    fi
    echo "$res"
}

install_err() {
    trap - EXIT
    if [[ -n $1 ]]; then
        install_msg "$@
If you don't know what to do, please contact support@radiasoft.net."
    fi
    exit 1
}

install_err_trap() {
    set +e
    trap - EXIT
    if [[ -z $install_verbose ]]; then
        tail -10 "$install_log_file"
    fi
    install_log 'Error trap'
    install_err 'Unexpected error; Install failed.'
    exit 1
}

install_exec() {
    install_log "$@"
    if [[ -n $install_verbose ]]; then
        "$@" 2>&1 | tee -a $install_log_file
    else
        "$@" >> $install_log_file 2>&1
    fi
}

install_info() {
    local f=install_msg
    if [[ -n $install_verbose ]]; then
        install_log "$@" ...
    fi
    #TODO(robnagler) $install_silent
    $f "$@" ...
}

install_log() {
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$@" >> $install_log_file
    if [[ -n $install_verbose ]]; then
        install_msg "$@"
    fi
}

install_main() {
    # POSIT: name ends in install.log (see
    install_log_file=$PWD/radia-run-install.log
    if ! dd if=/dev/null of="$install_log_file" 2>/dev/null; then
        install_log_file=/tmp/$(date +%Y%m%d%H%M%S)-$RANDOM-$(basename "$install_log_file")
    fi
    install_msg "Log: $install_log_file"
    install_clean_cmds=()
    trap install_err_trap EXIT
    install_log install_main
    install_args "$@"
    install_dir_check
    if [[ -n $install_repo ]]; then
        install_repo
    else
        eval "$(install_download $install_type.sh)"
        "${install_type}_main"
    fi
    local f
    for f in "${install_clean_cmds[@]}"; do
        eval $f
    done
    trap - EXIT
}

install_msg() {
    echo "$@" 1>&2
}

install_radia_run() {
    local script=radia-run
    install_log "Creating $script"
    local guest_user=vagrant
    local guest_dir=/$guest_user
    # Command needs to be absolute (see containers/bin/build-docker.sh)
    local cmd=
    local uri=
    case $install_image in
        */radtrack)
            cmd=radia-run-radtrack
            ;;
        */sirepo)
            cmd="radia-run-sirepo $guest_dir $install_port"
            uri=/
            ;;
    esac
    cat > "$script" <<EOF
#!/bin/bash
#
# Invoke $install_type run on $cmd
#
radia_run_channel='$install_docker_channel'
radia_run_cmd='$cmd'
radia_run_container=\$(id -u -n)-\$(basename '$install_image')
radia_run_guest_dir='$guest_dir'
radia_run_guest_user='$guest_user'
radia_run_image='$install_image'
radia_run_interactive='$install_run_interactive'
radia_run_port='$install_port'
radia_run_type='$install_type'
radia_run_uri='$uri'
radia_run_x11='$install_x11'

$(declare -f install_msg install_err | sed -e 's,^install,radia_run,')
$(declare -f $(compgen -A function | grep '^radia_run_'))

radia_run_main "\$@"
EOF
    chmod +x "$script"
    local start=restart
    if [[ -n $install_run_interactive ]]; then
        start=start
    fi
    install_msg "To $start, enter this command in the shell:

./$script
"
    if [[ -z $install_run_interactive ]]; then
        exec "./$script"
    fi
}

install_tmp_dir() {
    export TMPDIR="$install_tmp_dir/install-$$-$RANDOM"
    mkdir -p "$TMPDIR"
    install_clean_cmds+=( "cd '$PWD'; rm -rf '$TMPDIR'" )
    cd "$TMPDIR"
}

install_type_default() {
    case "$(uname)" in
        [Dd]arwin)
            if [[ -n $(type -t vagrant) ]]; then
                install_type=vagrant
            else
                install_err 'Please install Vagrant and restart install'
            fi
            ;;
        [Ll]inux)
            if [[ -n $(type -t docker) ]]; then
                install_type=docker
            elif [[ -n $(type -t vagrant) ]]; then
                install_type=vagrant
            else
                install_err 'Please install Docker or Vagrant and restart install'
            fi
            ;;
        *)
            install_err "$(uname) is an unsupported system, sorry"
            ;;
    esac
}

install_repo() {
    if (( $# > 0 )); then
        install_repo=$1
        shift
        install_extra_args=( "$@" )
        install_type=repo
        install_no_dir_check=1
    fi
    local first rest
    if [[ ! $install_repo =~ / ]]; then
        first=download
        rest=installers/$install_repo
    elif [[ $install_repo =~ ^/*([^/].*[^/])/*$ ]]; then
        first=${BASH_REMATCH[1]%%/*}
        rest=
        if [[ $first != ${BASH_REMATCH[1]} ]]; then
            rest=${BASH_REMATCH[1]#*/}
        fi
    else
        install_err "$install_repo: invalid repo name"
    fi
    install_url "$first" "$rest"
    install_script_eval radiasoft-download.sh
}

install_script_eval() {
    local script=$1
    install_info "Running: $install_url/$script"
    local source="$(install_download "$script")"
    if [[ -z $source ]]; then
        install_err
    fi
    eval "$source"
}

install_url() {
    local repo=$1
    local rest=$2
    local channel
    if [[ ! $repo =~ / ]]; then
        repo=radiasoft/$repo
    fi
    if [[ $download_channel == file ]]; then
        install_url=file://$HOME/src/$repo/$rest
        return
    fi
    channel=$install_github_channel
    if [[ $repo == radiasoft/download ]]; then
        channel=$download_channel
    fi
    install_url=https://raw.githubusercontent.com/$repo/$channel/$rest
}

install_usage() {
    install_err "$@
usage: $install_prog [verbose|quiet] [docker|vagrant] [beamsim|python2|radtrack|sirepo|<installer>|*/*] [extra args]"
}

#
# Common radia-run-* functions: See install_radia_run
# Inline here so syntax checked and easier to edit.
#
radia_run_exec() {
    local cmd=( $@ )
    radia_run_prompt
    if [[ -n $radia_run_cmd ]]; then
        if [[ $radia_run_type == docker ]]; then
            cmd+=( /bin/bash -c )
        fi
        cmd+=( "cd; . ~/.bashrc; $radia_run_cmd" )
    fi
    "${cmd[@]}" &
}

radia_run_msg() {
    echo "$@" 1>&2
}

radia_run_prompt() {
    local stop='To stop the application virtual machine, run:

vagrant destroy -f'
    if [[ $radia_run_type == docker ]]; then
        stop="To stop the application container, run:

docker rm -f '$radia_run_container'"
    fi
    if [[ -n $radia_run_uri ]]; then
        radia_run_msg "Point your browser to:

http://127.0.0.1:$radia_run_port$radia_run_uri

$stop"
    elif [[ -n $radia_run_x11 ]]; then
        radia_run_msg "Starting X11 application. Window will show itself shortly.

$stop"
    fi

}

install_main "$@"
