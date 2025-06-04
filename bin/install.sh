#!/bin/bash
#
# Usage: curl https://radia.run | bash -s repo [args...]
#
# Find repos in radiasoft/download/installers or radiasoft/*/radiasoft-download.sh
# or any repo with a radiasoft-download.sh in its root.
#
set -euo pipefail

# Define all variables in functions. All functions must be prefixed with install_

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
        install_err "Usage: curl $install_server | bash -s repo [args...]
Must supply repo argument"
    fi
}

install_assert_pip_version() {
    declare package=$1
    declare version=$2
    declare note=$3
    declare e=$package==$version
    declare a=$(pip list --format=freeze 2>/dev/null | grep "$package"==)
    if [[ $a != $e ]]; then
        install_err "$e required and $a installed; $note; use pipdeptree to diagnose"
    fi
}

install_clean() {
    declare f
    for f in ${install_clean_cmds[@]+"${install_clean_cmds[@]}"}; do
        eval "$f" || true
    done
}

install_depot_server() {
    declare force=${1:-}
    if [[ ! $force && ${install_server:-github} != github ]]; then
        echo -n "$install_server"
        return
    fi
    echo -n "$install_depot_server"
}

install_download() {
    declare url=$1
    declare file res
    if [[ ! $url =~ ^[[:lower:]]+: ]]; then
        url=$install_url/$url
    fi
    declare x=( "${install_curl_flags[@]}" )
    install_info curl ${x[@]+"${x[@]}"} "$url"
    if [[ $url =~ ^https://api\.github\.com ]]; then
        x+=( --header 'Accept: application/vnd.github.raw' )
        if [[ ${GITHUB_TOKEN:-} ]]; then
            x+=( --header "Authorization: Bearer $GITHUB_TOKEN" )
        fi
    fi
    curl ${x[@]+"${x[@]}"} "$url"
}

install_export_this_script() {
    # POSIT: all functions prefixed by install_
    declare f
    echo 'set -eou pipefail'
    install_vars_export
    for f in $(compgen -A function install_); do
        declare -f "$f"
    done
}

install_file_from_stdin() {
    # read stdin (here doc), install in tgt if it is new or content or permissions changed
    # mode is a number (compatible with stat %a); user & group are names
    # Implementation can be used in subshells with: $(declare -f install_file_from_stdin)
    # so keep implementation free of any but the simplest dependencies
    declare mode=$1
    declare owner=$2
    declare group=$3
    declare tgt=$4
    # bash read -r -d '' adds an extra newline, because it reads until null
    declare src=$(cat)
    if ! cmp -s "$tgt" - <<<"$src" || [[ $(stat --format '%a %U %G' "$tgt") != "$mode $owner $group" ]]; then
        # Can't use --compare, because stdin
        install --mode="$mode" --owner="$owner" --group="$group" --no-target-directory /dev/stdin "$tgt" <<<"$src"
    fi
}

install_foss_server() {
    # foss is best served from depot_sever, because the sources
    # are static and large. You can override this by setting
    # $install_depot_server.
    echo -n "$(install_depot_server force)"/foss
}

install_git_clone() {
    # repo of the form repo, org/repo or https://git-server/org/repo{.git,}
    # You can set RADIA_RUN_GIT_CLONE_BRANCH_<REPO> to clone a specific branch.
    # RADIA_RUN_*  carries inside containers and ssh (see install_vars_export).
    declare repo=$1
    declare b=${repo##*/}
    if [[ $b == $repo ]]; then
        repo=radiasoft/$repo
    fi
    # If not already an absolute file or uri
    if [[ ! $repo =~ ^(/|[A-Za-z]+:) ]]; then
        repo=https://github.com/$repo
    fi
    if [[ $repo =~ ^https://github.com(.+) && ${GITHUB_TOKEN:+1} ]]; then
        repo=https://$GITHUB_TOKEN@github.com/${BASH_REMATCH[1]}
    fi
    b=${b%%.git}
    b=${b^^}
    b=RADIA_RUN_GIT_CLONE_BRANCH_${b//[^A-Z0-9_]/_}
    b=${!b:-}
    git clone -q -c advice.detachedHead=false --depth 1 ${b:+--branch "$b"} "$repo"
}

install_err() {
    declare -a msg=( "$@" )
    trap - EXIT
    install_err_stack "${FUNCNAME[@]:-}"
    if (( ${#msg[@]} > 0 )); then
        install_msg "${msg[*]}
If you don't know what to do, please contact support@radiasoft.net."
    fi
    if [[ -z $install_verbose ]]; then
        install_clean >& /dev/null
    fi
    # POSIT: errexit compatible with calling functions
    exit 1
}

install_err_stack() {
    if (( $# <= 1)); then
        return
    fi
    declare funcs=( "$@" )
    if [[ "${funcs[1]}" == install_err_trap ]]; then
        # install_err called by install_err_trap, stack already printed
        return
    fi
    declare f
    install_msg 'bash stack:'
    for f in "${funcs[@]:1}"; do
        install_msg "  $f"
    done
}

install_err_trap() {
    set +e
    trap - EXIT
    install_err_stack "${FUNCNAME[@]:-}"
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
    declare f=install_msg
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
    install_init_vars_servers
    install_init_vars_basic_options
    install_init_vars_basic
    install_init_vars_versions
    install_init_vars_virt
    install_init_vars_oci
    eval "$(install_vars_export)"
}

install_init_vars_basic() {
    install_clean_cmds=()
    install_curl_flags=( --fail --location --silent --show-error )
    # For error messages
    install_log_file=$PWD/radia-run-install.log
    if ! dd if=/dev/null of="$install_log_file" 2>/dev/null; then
        install_log_file=/tmp/$(date +%Y%m%d%H%M%S)-$RANDOM-$(basename "$install_log_file")
    fi
    install_extra_args=()
    install_prog="curl $install_server | bash -s"
    install_repo=
    install_script_dir=
    if [[ ! -w $install_tmp_dir ]]; then
        install_tmp_dir=/var/tmp
    fi
    if [[ ! -w ${TMPDIR:-/tmp} ]]; then
        unset TMPDIR
    fi
    install_url=
}

install_init_vars_basic_options() {
    install_channel_is_default=
    : ${install_tmp_dir:=/var/tmp}
    : ${install_debug:=}
    if [[ ! ${install_channel-} ]]; then
        install_channel=prod
        install_channel_is_default=1
    fi
    : ${install_proprietary_key:=missing-proprietary-key}
    : ${install_verbose:=}
}

install_init_vars_oci() {
    if [[ ${RADIA_RUN_OCI_CMD:-} ]]; then
        if [[ ! $RADIA_RUN_OCI_CMD =~ ^(docker|podman)$ ]]; then
            install_err "invalid RADIA_RUN_OCI_CMD=$RADIA_RUN_OCI_CMD; must be podman or docker"
        fi
        return
    fi
    # Prefer docker over podman unless user can't execute docker
    RADIA_RUN_OCI_CMD=docker
    if [[ $(type -p podman) \
        && ! ( $(type -p docker) && ( $EUID == 0 || $(groups) =~ docker ) ) \
    ]]; then
        RADIA_RUN_OCI_CMD=podman
    fi
    export RADIA_RUN_OCI_CMD
}

install_init_vars_versions() {
    declare x=/etc/os-release
    : ${install_version_fedora:=36}
    : ${install_version_python:=3.9.15}
    : ${install_version_python_venv:=py${install_version_python%%.*}}
    : ${install_version_centos:=7}
    # always set these vars
    if [[ -r $x ]]; then
        export install_os_release_id=$(source "$x"; echo "${ID,,}")
        export install_os_release_version_id=$(source "$x"; echo "$VERSION_ID")
        return
    fi
    # COMPAT: darwin doesn't support ${x,,}
    export install_os_release_id=$(uname | tr A-Z a-z)
    if install_os_is_darwin; then
        export install_os_release_version_id=$(sw_vers -productVersion)
    else
        # Have something legal; unlikely to get here
        export install_os_release_version_id=0
    fi
}

install_init_vars_servers() {
    # POSIT: index.sh defaults to radia.run
    declare s=https://radia.run
    : ${install_server:=$s}
    if [[ ! ${install_depot_server:-} ]]; then
        if [[ $install_server == github ]]; then
            install_depot_server=$s/depot
        else
            install_depot_server=$install_server/depot
        fi
    fi
}

install_init_vars_virt() {
    export install_virt_docker=
    export install_virt_virtualbox=
    # https://stackoverflow.com/a/46436970
    declare f=/proc/1/cgroup
    if [[ -r $f ]] && grep -s -q /docker "$f" || [[ -e /.dockerenv ]] || [[ ${container:-} == oci ]]; then
        export install_virt_docker=1
    fi

    f=/dev/disk/by-id
    # disk works outside docker, but inside docker systemd-detect-virt works
    if [[ -r $f && $(ls "$f") =~ VBOX ]] || [[ $(systemd-detect-virt --vm 2>/dev/null || true) == oracle ]]; then
        export install_virt_virtualbox=1
    fi
}

install_main() {
    # POSIT: name ends in install.log
    install_init_vars
    trap install_err_trap EXIT
    install_msg "Log: $install_log_file"
    install_log install_main
    install_args "$@"
    install_repo_internal
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

install_os_is_almalinux() {
    [[ $install_os_release_id =~ almalinux ]]
}

install_os_is_rhel_compatible() {
    install_os_is_almalinux || [[ $install_os_release_id =~ centos ]]
}


install_os_is_centos_7() {
    [[ $install_os_release_id =~ centos ]] && [[ $install_os_release_version_id == 7 ]]
}

install_os_is_darwin() {
    [[ $install_os_release_id =~ darwin ]]
}

install_os_is_fedora() {
    [[ $install_os_release_id =~ fedora ]]
}

install_os_is_redhat() {
    [[ $install_os_release_id =~ rhel ]] || install_os_is_fedora || install_os_is_rhel_compatible
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

install_repo() {
    install_err 'install_repo is deprecated, use install_repo_eval'
}

install_repo_as_root() {
    install_repo_as_user root "$@"
}

install_repo_as_user() {
    declare user=$1
    shift
    declare s=$(install_export_this_script)
    s+='
install_main "$@"'
    if [[ $(id -u "$user") == $EUID ]]; then
        # environment is cascaded so no need for --login
        bash -s "$@" <<<"$s"
        return
    fi
    # Current directory might be inaccessible inside sudo
    declare prev_pwd=$PWD
    cd /
    # Need login environment for the user
    install_sudo "--user=$user" bash --login -s "$@" <<<"$s"
    cd "$prev_pwd"
}

install_repo_eval() {
    declare prev_pwd=$PWD
    # don't run in a subshell so can add to environment,
    # but don't override these vars.
    install_extra_args=() \
        install_depot_server="$install_depot_server" \
        install_repo= \
        install_script_dir="$install_script_dir" \
        install_server="$install_server" \
        install_url= \
        install_repo_internal "$@"
    cd "$prev_pwd"
}

install_repo_internal() {
    if (( $# > 0 )); then
        install_repo=$1
        shift
        install_extra_args=( "$@" )
        install_script_dir=
    fi
    declare first rest
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

install_script_eval() {
    declare script=$1
    if [[ ! $install_script_dir ]]; then
        declare pwd=$PWD
        install_tmp_dir
        install_script_dir=$PWD
        cd "$pwd"
    fi
    declare source=$install_script_dir/$(date +%Y%m%d%H%M%S)-$(basename "$script")
    install_download "$script" > "$source"
    if [[ ! -s $source ]]; then
        install_err "error downloading script=$script"
    fi
    if [[ ! $(head -1 "$source") =~ ^#! ]]; then
        install_err "$script: no #! at start of file: $source"
    fi
    # Caculate main function before sourcing
    declare m=$(basename "$script" .sh)
    if [[ "$script" == radiasoft-download.sh ]]; then
        # POSIT: same special case in install_url()
        if [[ $install_url =~ ^https://api.github.com/repos/[^/]+/([^/]+)/contents$ ]]; then
            m=${BASH_REMATCH[1]}
        else
            m=$(basename "$install_url")
        fi
    fi
    # type -t checks below validate the identifier via checking if they are a function
    m=${m//-/_}_main
    # three cases: main without args or with install_extra_args
    # Be loose in case there's a bug. Compliant scripts must
    # not call main in any form
    if grep -E "^$m( *| .*@.*)$" "$source" >&/dev/null; then
        # main is called in script so don't call again
        m=
    elif [[ $(type -t "$m") == function ]]; then
        # Delete in case repo (or same name) was evaled already and
        # new one doesn't have $m defined as a function.
        unset -f "$m"
    fi
    install_info "Source: $source"
    source "$source"
    if [[ $(type -t "$m") == function ]]; then
        $m ${install_extra_args[@]+"${install_extra_args[@]}"}
    fi
}

install_source_bashrc() {
    install_not_strict_cmd source "$HOME"/.bashrc
}

install_sudo() {
    declare sudo=
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
    declare repo=$1
    declare rest=${2:-}
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
    declare f
    declare x=(
        install_server
        install_channel
        install_debug
        install_depot_server
        install_proprietary_key
        install_version_fedora
        install_version_python
        install_version_centos
        $(compgen -A variable RADIA_RUN_)
        $(compgen -A variable GITHUB_)
    )
    for f in "${x[@]}"; do
        export "$f"
        echo "$(declare -p $f);"
    done
}

install_version_fedora_lt_36() {
    (( $install_version_fedora < 36 ))
}

install_yum() {
    declare args=( "$@" )
    declare cmd=$1
    declare yum=yum
    declare flags=( -y )
    if [[ $(type -t dnf5) ]]; then
        yum=dnf5
    else
        # dnf5 does not support --color
        flags+=( --color=never )
        if [[ $(type -t dnf) ]]; then
            yum=dnf
        fi
    fi
    if [[ ! $install_debug ]]; then
        flags+=( -q )
    fi
    if [[ ${args[0]} != repolist ]]; then
        install_info "$yum" "${args[@]}"
    fi
    # cat prevents color output in dnf5
    install_sudo "$yum" "${flags[@]}" "${args[@]}" | cat
}

install_yum_add_repo() {
    declare repo=$1
    if [[ -r /etc/yum.repos.d/${repo##*/} ]]; then
        return
    fi
    if [[ $(type -t dnf5) ]]; then
        if [[ $(readlink /usr/bin/dnf) != dnf5 ]]; then
            install_err 'dnf6 or above is not supported'
        fi
        install_yum_install dnf-plugins-core
        install_yum addrepo --from-repofile="$repo"
    elif [[ $(type -t dnf) ]]; then
        # dnf 4 or before
        install_yum_install dnf-plugins-core
        install_yum config-manager --add-repo "$repo"
    elif [[ $(type -t yum-config-manager) ]]; then
        yum-config-manager --add-repo "$repo"
        install_yum makecache fast
    else
        install_err "install_yum_add_repo does not support os=$install_os_release_id"
    fi
}

install_yum_install() {
    declare -a flags=()
    while [[ ${1:-} =~ ^- ]]; do
        flags+=( "$1" )
        shift
    done
    declare x y todo=()
    for x in "$@"; do
        y=$x
        # Get real name from file or url, which contains a slash or ends in .rpm.
        # Note this checks the version explicitly, which is a
        # different behavior from when the arg is a simple name.
        if [[ $x =~ (/|\.rpm$) ]]; then
            x=$(rpm -qp "$y")
            if [[ ! $x ]]; then
                install_err "install_yum_install invalid rpm=$y"
            fi
        fi
        # even if $x is empty (above) then will append to todo
        if ! rpm -q "$x" >& /dev/null; then
            todo+=( "$y" )
        fi
    done
    if (( ${#todo[@]} <= 0 )); then
        return
    fi
    install_yum install "${flags[@]:-}" "${todo[@]}"
}

install_main "$@"
