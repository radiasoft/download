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
#     install_server=~/src bash ../../bin/install.sh code
set -e -o pipefail

install_args() {
    if [[ -n $download_channel ]]; then
        install_err '$download_channel: unsupported, use $install_server'
    fi
    while [[ ${1:-} ]]; do
        case "$1" in
            beamsim|python2|rs4pi|sirepo)
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
                # master fixed up in install_args_check
                install_channel=$1
                ;;
            quiet)
                install_verbose=
                ;;
            *)
                install_repo=$1
                shift
                install_type=repo
                install_extra_args=( "$@" )
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
        if [[ ! $install_image =~ ^(beamsim|python2|rs4pi|sirepo)$ ]]; then
            install_usage "Please supply an install name: beamsim, python2, rs4pi, sirepo, OR repo name"
        fi
    fi
    case $install_type in
        repo)
            install_no_dir_check=1
            ;;
        vagrant|docker)
            if [[ $install_image =~ sirepo|rs4pi ]]; then
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
            if [[ $install_image =~ ^radiasoft/(beamsim|python2|rs4pi)$ ]]; then
                install_docker_channel=alpha
            fi
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
    install_url radiasoft/download bin
}

install_clean() {
    local f
    for f in "${install_clean_cmds[@]}"; do
        eval $f
    done >& /dev/null
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
    local file res
    if [[ ! $url =~ ^[[:lower:]]+: ]]; then
        url=$install_url/$url
    fi
    install_info curl "${install_curl_flags[@]}" "$url"
    if [[ $url =~ raw.github ]]; then
        # work around github's raw cache
        url="$url?$(date +%s)"
    fi
    curl "${install_curl_flags[@]}" "$url"
}

install_err() {
    trap - EXIT
    if [[ -n $1 ]]; then
        install_msg "$*
If you don't know what to do, please contact support@radiasoft.net."
    fi
    if [[ -z $install_verbose ]]; then
        install_clean >& /dev/null
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
    # Just in case install_err doesn't work
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
        install_verbose= install_log "$@"
    fi
    #TODO(robnagler) $install_silent
    $f "$@"
}

install_log() {
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$@" >> $install_log_file
    if [[ -n $install_verbose ]]; then
        install_msg "$@"
    fi
}

install_init_vars() {
    # For error messages
    install_prog='curl radia.run | bash -s'
    install_log_file=$PWD/radia-run-install.log
    if ! dd if=/dev/null of="$install_log_file" 2>/dev/null; then
        install_log_file=/tmp/$(date +%Y%m%d%H%M%S)-$RANDOM-$(basename "$install_log_file")
    fi
    install_clean_cmds=()
    : ${install_channel:=not-set}
    : ${install_debug:=}
    : ${install_server:=github}
    : ${install_tmp_dir:=/var/tmp}
    : ${install_verbose:=}
    install_curl_flags=( -L -s -S )
    install_extra_args=()
    install_image=
    install_repo=
    install_run_interactive=
    install_script_dir=
    install_type=
    install_url=
    if [[ ! -w $install_tmp_dir ]]; then
        install_tmp_dir=/var/tmp
    fi
    if [[ ! -w $TMPDIR ]]; then
        unset TMPDIR
    fi
    if [[ $install_server =~ ^file://(/.+) && ! -r ${BASH_REMATCH[1]}/radiasoft/download ]]; then
        install_server=github
    fi
}

install_main() {
    # POSIT: name ends in install.log (see
    install_init_vars
    trap install_err_trap EXIT
    install_msg "Log: $install_log_file"
    install_log install_main
    install_args "$@"
    install_dir_check
    if [[ -n $install_repo ]]; then
        install_repo
    else
        install_script_eval "$install_type.sh"
        "${install_type}_main"
    fi
    install_clean
    if [[ -z $install_verbose ]]; then
        rm -f "$install_log_file"
    fi
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
    local db=
    local daemon=
    local tini='exec /home/vagrant/.radia-run/tini -- /home/vagrant/.radia-run/start'
    case $install_image in
        */sirepo)
            db=/sirepo
            cmd=$tini
            uri=/
            daemon=1
            ;;
        */rs4pi)
            db=/sirepo
            cmd=$tini
            uri=/robot
            daemon=1
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
radia_run_daemon='$daemon'
radia_run_db_dir='$db'
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
    export TMPDIR="$install_tmp_dir/radia-run-$$-$RANDOM"
    mkdir -p "$TMPDIR"
    install_clean_cmds+=( "cd '$PWD'; rm -rf '$TMPDIR'" )
    cd "$TMPDIR"
}

install_type_default() {
    case "$(uname)" in
        [Dd]arwin|[Ll]inux)
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
        install_script_dir=
    fi
    local first rest
    if [[ ! $install_repo =~ / ]]; then
        if [[ $install_repo =~ \.sh$ ]]; then
            install_url ''
            install_script_eval "$install_repo"
            return
        fi
        first=download
        rest=installers/$install_repo
    elif [[ $install_repo =~ ^/*([^/].*[^/])/*$ ]]; then
        first=${BASH_REMATCH[1]}
        if [[ $first =~ ^([^/]+/[^/]+)/(.+)$ ]]; then
            first=${BASH_REMATCH[1]}
            rest=${BASH_REMATCH[2]}
        elif [[ $first =~ ^([^/]+/[^/]+)$ ]]; then
            rest=
        fi
    fi
    if [[ ! $first ]]; then
        install_err "$install_repo: invalid repo name"
    fi
    if [[ ! $first =~ / ]]; then
        first=radiasoft/$first
    fi
    install_url "$first" "$rest"
    install_script_eval radiasoft-download.sh
}

install_repo_as_root() {
    (
        install_url radiasoft/download bin
        install_download index.sh
    ) | install_sudo "install_server=$install_server" "install_channel=$install_channel" "install_debug=$install_debug" bash -s "$@"
}

install_repo_eval() {
    local prev_args=( ${install_extra_args[@]+"${install_extra_args[@]}"} )
    local prev_pwd=$PWD
    local prev_repo=$install_repo
    local prev_script_dir=$install_script_dir
    local prev_server=$install_server
    local prev_type=$install_type
    local prev_url=$install_url
    install_repo "$@"
    cd "$prev_pwd"
    install_extra_args=( ${prev_args[@]+"${prev_args[@]}"} )
    install_repo=$prev_repo
    install_script_dir=$prev_script_dir
    install_server=$prev_server
    install_type=$prev_type
    install_url=$prev_url
}

install_script_eval() {
    local script=$1
    if [[ -z $install_script_dir ]]; then
        local pwd=$PWD
        install_tmp_dir
        install_script_dir=$PWD
        cd "$pwd"
    fi
    local source=$install_script_dir/$(date +%Y%m%d%H%M%S)-$(basename "$script")
    install_download "$script" > "$source"
    if [[ ! -s $source ]]; then
        install_err
    fi
    if [[ ! $(head -1 "$source") =~ ^#! ]]; then
        install_err "$url: no #! at start of file: $source"
    fi
    install_info "Source: $source"
    source "$source"
}

install_sudo() {
    local sudo
    if [[ $UID != 0 ]]; then
        sudo=sudo
    fi
    ${sudo:-} "$@"
}

install_url() {
    local repo=$1
    local rest=${2:-}
    case $install_server in
        github)
            local channel=$install_github_channel
            if [[ $repo == radiasoft/download ]]; then
                channel=master
            fi
            install_url=https://raw.githubusercontent.com/$repo/$channel
            ;;
        /*)
            install_server=file://$install_server
            install_url=$install_server/$repo
            ;;
        http:*|https:*|file:*)
            install_url=$install_server/$repo
            ;;
        *)
            install_err "$install_server: unknown install_server format"
            ;;
    esac
    if [[ -n $rest ]]; then
        install_url=$install_url/$rest
    fi
}

install_usage() {
    install_err "$@
usage: $install_prog [verbose|quiet] [docker|vagrant] [beamsim|python2|rs4pi|sirepo|<installer>|*/*] [extra args]"
}

install_yum_install() {
    local x todo=()
    for x in "$@"; do
        if ! rpm -q "$x" >& /dev/null; then
            todo+=( "$x" )
        fi
    done
    if (( ${#todo[@]} <= 0 )); then
        return
    fi
    local cmd=yum
    if [[ $(type -t dnf) ]]; then
        cmd=dnf
    fi
    install_info "$cmd" install "${todo[@]}"
    install_sudo "$cmd" install --color=never -y -q "${todo[@]}"
}

#
# Common radia-run-* functions: See install_radia_run
# Inline here so syntax checked and easier to edit.
#
radia_run_exec() {
    local cmd=( "$@" )
    radia_run_prompt
    if [[ -n $radia_run_cmd ]]; then
        if [[ $radia_run_type == docker ]]; then
            cmd+=( /bin/bash -c )
        fi
        cmd+=( "cd; . ~/.bashrc; $radia_run_cmd" )
    fi
    if [[ $radia_run_daemon ]]; then
        "${cmd[@]}" >& radia-run.log &
    else
        "${cmd[@]}"
    fi
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
