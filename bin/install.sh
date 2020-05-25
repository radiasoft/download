#!/bin/bash
#
# Usage: curl https://depot.radiasoft.org | bash -s [repo args...]
#
# Find repos in radiasoft/download/installers or radiasoft/*/radiasoft-download.sh
# or any repo with a radiasoft-download.sh in its root.
#
set -euo pipefail

install_args() {
    while [[ ${1:-} ]]; do
        case "$1" in
            alpha|beta|dev|prod)
                install_channel=$1
                install_channel_is_default=
                ;;
            debug)
                install_debug=1
                install_verbose=1
                ;;
            quiet)
                install_debug=
                install_verbose=
                ;;
            verbose)
                install_verbose=1
                ;;
            *)
                install_repo=$1
                shift
                install_extra_args=( "$@" )
                break
                ;;
        esac
        shift
    done
    if [[ -n $install_debug ]]; then
        if [[ ${BASH_SOURCE:-} ]]; then
            export PS4='+ [${BASH_SOURCE##*/}:${LINENO}] '
        fi
        set -x
    fi
    if [[ ! $install_repo ]]; then
        install_repo=$install_default_repo
    fi
}

install_bivio_mpi_lib() {
    if [[ ${BIVIO_MPI_LIB:-} ]]; then
        return
    fi
    # we do not build with Shifter so this isn't included
    # see biviosoftware/home-env/bashrc.d/zz-10-base.sh
    # /opt/udiImage/modules/mpich/lib64
    for f in \
        /usr/local/lib \
        /usr/lib64/mpich/lib \
        /usr/lib64/openmpi/lib
    do
        if [[ ! ${BIVIO_MPI_LIB:-} && -d $f && $(shopt -s nullglob && echo $f/libmpi.so*) ]]; then
            export BIVIO_MPI_LIB=$f
            break
        fi
    done
}

install_clean() {
    local f
    for f in "${install_clean_cmds[@]}"; do
        eval $f
    done >& /dev/null
}

install_depot_server() {
    local force=${1:-}
    if [[ ! $force && ${install_server:-github} != github ]]; then
        echo -n "$install_server"
        return
    fi
    echo -n "$install_depot_server"
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

install_foss_server() {
    # foss is best served from depot_sever, because the sources
    # are static and large. You can override this by setting
    # $install_depot_server.
    echo -n "$(install_depot_server force)"/foss
}

install_proprietary_server() {
    # proprietary is best served from the $install_server, which
    # will be the local server (dev). Having a copy of the code
    # locally in dev is better than sharing the proprietary
    # key in dev.
    echo -n "$install_server/$install_proprietary_key"
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
    install_log_file=$PWD/radia-run-install.log
    if ! dd if=/dev/null of="$install_log_file" 2>/dev/null; then
        install_log_file=/tmp/$(date +%Y%m%d%H%M%S)-$RANDOM-$(basename "$install_log_file")
    fi
    install_clean_cmds=()
    install_channel_is_default=
    if [[ ! ${install_channel-} ]]; then
        install_channel=prod
        install_channel_is_default=1
    fi
    # TODO(robnagler) remove once home-env updated everywhere
    install_bivio_mpi_lib
    : ${install_debug:=}
    : ${install_default_repo:=container-run}
    : ${install_server:=github}
    : ${install_tmp_dir:=/var/tmp}
    : ${install_verbose:=}
    : ${install_proprietary_key:=missing-proprietary-key}
    install_curl_flags=( -L -s -S )
    install_extra_args=()
    install_repo=
    install_script_dir=
    install_url=
    if [[ ! -w $install_tmp_dir ]]; then
        install_tmp_dir=/var/tmp
    fi
    if [[ ! -w ${TMPDIR:-/tmp} ]]; then
        unset TMPDIR
    fi
    if [[ $install_server =~ ^file://(/.+) && ! -r ${BASH_REMATCH[1]}/radiasoft/download ]]; then
        install_server=github
    fi
    : ${install_depot_server:=https://depot.radiasoft.org}
    install_prog="curl $install_depot_server | bash -s"
}

install_main() {
    # POSIT: name ends in install.log
    install_init_vars
    trap install_err_trap EXIT
    install_msg "Log: $install_log_file"
    install_log install_main
    install_args "$@"
    install_repo
    install_clean
    if [[ -z $install_verbose ]]; then
        rm -f "$install_log_file"
    fi
    trap - EXIT
}

install_msg() {
    echo "$@" 1>&2
}

install_not_strict_cmd() {
    set +euo pipefail
    "$@"
    set -euo pipefail
}

install_repo() {
    if (( $# > 0 )); then
        install_repo=$1
        shift
        install_extra_args=( "$@" )
        install_script_dir=
    fi
    local first rest
    if [[ ! ${install_repo:-/} =~ / ]]; then
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
    install_repo_as_user root "$@"
}

install_repo_as_user() {
    local user=$1
    shift
    local sudo=
    if [[ $(id -u -n) == $user ]]; then
        # passing env vars on the command line is
        # tricky so this is the easiest way
        (
            install_url radiasoft/download bin
            install_download index.sh
        ) | install_server="$install_server" \
            install_channel="$install_channel" \
            install_debug="$install_debug" \
            bash -l -s "$@"
        return
    fi
    (
        install_url radiasoft/download bin
        install_download index.sh
    ) | (
        # Current directory might be inaccessible
        cd /
        install_sudo "--user=$user" \
            install_server="$install_server" \
            install_channel="$install_channel" \
            install_debug="$install_debug" \
            bash -l -s "$@"
    )
}

install_repo_eval() {
    local prev_pwd=$PWD
    # don't run in a subshell so can add to environment,
    # but don't override these vars.
    install_extra_args=() \
        install_repo= \
        install_script_dir="$install_script_dir" \
        install_server="$install_server" \
        install_url= \
        install_repo "$@"
    cd "$prev_pwd"
}

install_script_eval() {
    local script=$1
    if [[ ! $install_script_dir ]]; then
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
        install_err "$script: no #! at start of file: $source"
    fi
    local m=
    if [[ "$script" == radiasoft-download.sh ]]; then
        # before sourcing, which can modify anything
        local f=$(basename "$install_url")
        f=${f//-/_}_main
        # three cases: main without args or with install_extra_args
        # Be loose in case there's a bug. Compliant scripts must
        # not call main in any form
        if ! egrep "^$f( *| .*@.*)$" "$source" >&/dev/null; then
            m=$f
            # Just in case repo was evaled already
            unset "$m"
        fi
    fi
    install_info "Source: $source"
    source "$source"
    if [[ $m && $(type -t "$m") == function ]]; then
        $m ${install_extra_args[@]+"${install_extra_args[@]}"}
    fi
}

install_source_bashrc() {
    install_not_strict_cmd source "$HOME"/.bashrc
}

install_sudo() {
    local sudo=
    if [[ $EUID != 0 || $1 =~ ^- ]]; then
        sudo=sudo
    fi
    $sudo "$@"
}

install_tmp_dir() {
    export TMPDIR="$install_tmp_dir/radia-run-$$-$RANDOM"
    mkdir -p "$TMPDIR"
    install_clean_cmds+=( "cd '$PWD'; rm -rf '$TMPDIR'" )
    cd "$TMPDIR"
}

install_url() {
    local repo=$1
    local rest=${2:-}
    case $install_server in
        github)
            install_url=https://raw.githubusercontent.com/$repo/master
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
usage: $install_prog [verbose|quiet] [<installer>|*/*] [extra args]"
}

install_vars_export() {
    echo "export install_server='$install_server' install_channel='$install_channel' install_debug='$install_debug' install_depot_server='$install_depot_server' install_proprietary_key='$install_proprietary_key'"
}

install_yum() {
    local args=( "$@" )
    local yum=yum
    if [[ $(type -t dnf) ]]; then
        yum=dnf
    fi
    local flags=( -y --color=never )
    if [[ ! $install_debug ]]; then
        flags+=( -q )
    fi
    install_info "$yum" "${args[@]}"
    install_sudo "$yum" "${flags[@]}" "${args[@]}"
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
    install_yum install "${todo[@]}"
}

install_main "$@"
