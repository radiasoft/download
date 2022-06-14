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
            export PS4='+ [${BASH_SOURCE:+${BASH_SOURCE##*/}}:${LINENO}] '
        fi
        set -x
    fi
    if [[ ! $install_repo ]]; then
        install_repo=$install_default_repo
    fi
}

install_assert_pip_version() {
    local package=$1
    local version=$2
    local note=$3
    local e=$package==$version
    local a=$(pip list --format=freeze 2>/dev/null | grep "$package"==)
    if [[ $a != $e ]]; then
        install_err "$e required and $a installed; $note; use pipdeptree to diagnose"
    fi
}

install_clean() {
    local f
    for f in ${install_clean_cmds[@]+"${install_clean_cmds[@]}"}; do
        eval "$f" || true
    done
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
    local x=( "${install_curl_flags[@]}" )
    install_info curl ${x[@]+"${x[@]}"} "$url"
    if [[ $url =~ https://api.github.com ]]; then
        x+=( -H 'Accept: application/vnd.github.raw' )
    fi
    curl ${x[@]+"${x[@]}"} "$url"
}

install_foss_server() {
    # foss is best served from depot_sever, because the sources
    # are static and large. You can override this by setting
    # $install_depot_server.
    echo -n "$(install_depot_server force)"/foss
}

install_pip_install() {
    # --no-color does not work always
    # --progress-bar=off seems to work
    # but this seems to work always
    pip install "$@" | cat
}

install_pip_uninstall() {
    # we don't care if uninstall work
    pip uninstall -y "$@" >& /dev/null || true
}

install_proprietary_server() {
    # proprietary is best served from the $install_server, which
    # will be the local server (dev). Having a copy of the code
    # locally in dev is better than sharing the proprietary
    # key in dev.
    echo -n "$(install_depot_server)/$install_proprietary_key"
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
    install_os_release_vars
    install_virt_vars
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
    : ${RADIA_RUN_VERSION_FEDORA:=36}
    : ${RADIA_RUN_VERSION_PYTHON:=3.10.5}
    eval "$(install_vars_export)"
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
        rm -f "$install_log_file" >& /dev/null || true
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

install_os_release_vars() {
    local x=/etc/os-release
    # always update
    if [[ -r /etc/os-release ]]; then
        export install_os_release_id=$(source "$x"; echo "$ID")
        export install_os_release_version_id=$(source "$x"; echo "$VERSION_ID")
        return
    fi
    export install_os_release_id=$(uname | tr A-Z a-z)
    if [[ $install_os_release_id == darwin ]]; then
        # Probably not important, but do something legit by deleting patch version
        export install_os_release_version_id=$(
            sw_vers -productVersion | perl -p -e 's{\.\d+$}{}'
        )
    else
        # Have something legal; unlikely to get here
        export install_os_release_version_id=0
    fi
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
            install_depot_server="$install_depot_server" \
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
            install_depot_server="$install_depot_server" \
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
        install_depot_server="$install_depot_server" \
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
    install_clean_cmds+=( "if [[ -e '$TMPDIR' && -e '$PWD' ]]; then cd '$PWD' && rm -rf '$TMPDIR'; fi" )
    cd "$TMPDIR"
}

install_url() {
    local repo=$1
    local rest=${2:-}
    case $install_server in
        github)
            install_url=https://api.github.com/repos/$repo/contents
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
    for f in install_server install_channel install_debug install_depot_server install_proprietary_key $(compgen -A variable RADIA_RUN_); do
        export "$f"
        echo "$(declare -p $f);"
    done
}

install_virt_vars() {
    export install_virt_docker=
    export install_virt_virtualbox=
    # https://stackoverflow.com/a/46436970
    local f=/proc/1/cgroup
    if [[ -r $f ]] && grep -s -q /docker "$f" || [[ -e /.dockerenv ]]; then
        export install_virt_docker=1
    fi

    f=/dev/disk/by-id
    # disk works outside docker, but inside docker systemd-detect-virt works
    if [[ -r $f && $(ls "$f") =~ VBOX ]] || [[ $(systemd-detect-virt --vm 2>/dev/null || true) == oracle ]]; then
        export install_virt_virtualbox=1
    fi
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
    local x y todo=()
    for x in "$@"; do
        y=$x
        if [[ $x =~ ^https?:// ]]; then
            x=$(rpm -q "$y" 2>/dev/null || true)
        fi
        # even if $x is empty (above) then will append to todo
        if ! rpm -q "$x" >& /dev/null; then
            todo+=( "$y" )
        fi
    done
    if (( ${#todo[@]} <= 0 )); then
        return
    fi
    install_yum install "${todo[@]}"
}

install_main "$@"
