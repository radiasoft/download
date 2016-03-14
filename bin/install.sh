#!/bin/bash
#
# Install RadiaSoft containers
#
# TODO(robnagler):
#    - delegated argument parsing
#    - modularize better (delegation model to other repos?)
#    - add codes.sh (so can install locally and remotely)
#    - leave in directory match? (may be overkill on automation)
#    - handle no tty case better (not working?)
#    - add channels
#    - generalized bundling with versions
#    - add test of dynamic download and static on travis (trigger for dynamic?)
#    - tests for individual codes
set -e

install_args() {
    install_type=
    install_image=
    install_verbose=
    install_run_interactive=
    install_repo=
    install_extra_args=()
    while [[ "$1" ]]; do
        case "$1" in
            beamsim|isynergia|python2|radtrack|sirepo)
                install_image=$1
                ;;
            synergia)
                install_image=$1
                ;;
            vagrant|docker|github)
                install_type=$1
                ;;
            verbose)
                install_verbose=1
                ;;
            quiet)
                install_verbose=
                ;;
            */*)
                install_repo=$1
                install_type=github
                shift
                install_extra_args=$@
                break
                ;;
            *)
                install_usage "$1: unknown install option"
                ;;
        esac
        shift
    done
    install_args_check
}

install_args_check() {
    if [[ ! $install_type ]]; then
        install_type_default
    fi
    if [[ $install_repo ]]; then
        if [[ $install_type != github ]]; then
            install_usage "$install_type: $install_repo must be installed with github"
        fi
    elif [[ ! $install_image && ! $install_repo ]]; then
        install_image=$(basename "$PWD")
        if [[ ! $install_image =~ ^(beamsim|isynergia|python2|radtrack|sirepo)$ ]]; then
            install_usage "Please supply an install name: beamsim, isynergia, python2, radtrack, sirepo, synergia"
        fi
    fi
    case $install_type in
        github)
            install_no_dir_check=1
            ;;
        vagrant|docker)
            if [[ $install_image == synergia ]]; then
                install_msg 'Switching image to "beamsim" which includes synergia'
                install_image=beamsim
            fi
            if [[ $install_image == isynergia ]]; then
                if [[ $install_type == docker ]]; then
                    install_no_dir_check=1
                else
                    install_usage 'isynergia is only supported for docker'
                fi
            fi
            if [[ $install_image == radtrack ]]; then
                install_x11=1
            fi
            if [[ $install_image =~ isynergia|sirepo ]]; then
                install_port=8000
            fi
            install_image=radiasoft/$install_image
            ;;
    esac
    if [[ $install_image =~ beamsim|isynergia|python2 ]]; then
        install_run_interactive=1
    fi
    install_url=https://raw.githubusercontent.com/radiasoft/download/master/bin
}

install_dir_check() {
    if [[ $install_no_dir_check ]]; then
        return
    fi
    # Loose check of our files. Just need to make sure
    if [[ $(ls -A | egrep -v '(install.log|radia-run|\.bivio_vagrant_ssh|Vagrantfile)') ]]; then
        install_err 'Current directory is not empty.
Please create a new directory, cd to it, and re-run this command.'
    fi
}

install_download() {
    local url=$1
    local base=$(basename "$url")
    local file=$(dirname "$0")/$base
    local res
    if [[ -r $file ]]; then
        res=$(<$file)
        install_log cat "$file"
    else
        if [[ $url == $base ]]; then
            url=$install_url/$base
        fi
        install_log curl -L -s -S "$url"
        res=$(curl -L -s -S "$url")
    fi
    if [[ ! $res =~ ^#! ]]; then
        install_err "Unable to download $url"
    fi
    echo "$res"
}

install_err() {
    trap - EXIT
    install_msg "$@
If you don't know what to do, please contact support@radiasoft.net."
    exit 1
}

install_err_trap() {
    set +e
    trap - EXIT
    if [[ ! $install_verbose ]]; then
        tail -10 "$install_log_file"
    fi
    install_log 'Error trap'
    install_err 'Unexpected error; Install failed.'
}

install_exec() {
    install_log "$@"
    if [[ $install_verbose ]]; then
        "$@" 2>&1 | tee -a $install_log_file
    else
        "$@" >> $install_log_file 2>&1
    fi
}

install_info() {
    local f=install_msg
    if [[ $install_verbose ]]; then
        install_log "$@" ...
    fi
    #TODO(robnagler) $install_silent
    $f "$@" ...
}

install_log() {
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$@" >> $install_log_file
    if [[ $install_verbose ]]; then
        install_msg "$@"
    fi
}

install_main() {
    install_log_file=$PWD/install.log
    install_clean_cmds=()
    trap install_err_trap EXIT
    install_log install_main
    install_args "$@"
    install_dir_check
    if [[ $install_repo ]]; then
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
            uri=/srw
            ;;
        */isynergia)
            cmd=synergia-ipython-beamsim
            uri=/
            ;;
    esac
    cat > "$script" <<EOF
#!/bin/bash
#
# Invoke $install_type run on $cmd
#
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
    if [[ $install_run_interactive ]]; then
        start=start
    fi
    install_msg "To $start, enter this command in the shell:

./$script
"
    if [[ ! $install_run_interactive ]]; then
        exec "./$script"
    fi
}

install_tmp_dir() {
    export TMPDIR=/var/tmp/install-$$-$RANDOM
    mkdir -p "$TMPDIR"
    install_clean_cmds+=( "cd '$PWD'; rm -rf '$TMPDIR'" )
    cd "$TMPDIR"
}

install_type_default() {
    case "$(uname)" in
        [Dd]arwin)
            if [[ $(type -t vagrant) ]]; then
                install_type=vagrant
            else
                install_err 'Please install Vagrant and restart install'
            fi
            ;;
        [Ll]inux)
            if [[ $(type -t docker) ]]; then
                install_type=docker
            elif [[ $(type -t vagrant) ]]; then
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
    if ! [[ $install_repo =~ ^/*([^/].*[^/])/*$ ]]; then
        install_err "$install_repo: invalid repo name"
    fi
    local first=${BASH_REMATCH[1]%%/*}
    local rest=
    if [[ $first != ${BASH_REMATCH[1]} ]]; then
        rest=${BASH_REMATCH[1]#*/}
    fi
    local x=radiasoft-download.sh
    local url=https://raw.githubusercontent.com/radiasoft/$first/master/$rest/$x
    if [[ -f $x ]]; then
        url=file://$PWD/$x
    fi
    install_info "Running: $url"
    eval "$(install_download $url)"
}

install_usage() {
    install_err "$@
usage: $(basename $0) [verbose|quiet] [docker|vagrant|github] [beamsim|isynergia|python2|radtrack|sirepo|synergia|*/*] [extra args]"
}

#
# Common radia-run-* functions: See install_radia_run
# Inline hear so syntax checked and easier to edit.
#
radia_run_exec() {
    local cmd=( $@ )
    radia_run_prompt
    if [[ $radia_run_cmd ]]; then
        if [[ $radia_run_type == docker ]]; then
            cmd+=( /bin/bash -c )
        fi
        cmd+=( "cd; . ~/.bashrc; $radia_run_cmd" )
    fi
    exec "${cmd[@]}"
}

radia_run_prompt() {
    if [[ $radia_run_uri ]]; then
        radia_run_msg "
Point your browser to:

http://127.0.0.1:$radia_run_port$radia_run_uri

Type control-C to stop the application.
"
    elif [[ $radia_run_x11 ]]; then
        radia_run_msg '
Starting X11 application. Window will show itself shortly.

Exit the window to stop the application.
'
    fi

}

install_main "$@"
