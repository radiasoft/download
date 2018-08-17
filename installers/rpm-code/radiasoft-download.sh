#!/bin/bash
# Copied from biviosoftware/rpm-perl. It's different, but rpm_code_install_rpm is the
# same
set -euo pipefail

: ${rpm_code_image:=radiasoft/beamsim-part1}

: ${rpm_code_user:=vagrant}

rpm_code_build() {
    local rpm_base=$1
    local rpm_base_src=$2
    local code=$3
    local version=$(date -u +%Y%m%d.%H%M%S)
    local -A rpm_code_build_exclude
    install_repo_eval code "$code"
    rpm_code_build_exclude_add "$(dirname "$rpm_code_build_src_dir")"
    rpm_code_build_exclude_add "$codes_bin_dir"
    rpm_code_build_exclude_add "$codes_lib_dir"
    local i
    local exclude=()
    for i in "${!rpm_code_build_exclude[@]}"; do
        exclude+=( --rpm-auto-add-exclude-directories "$i" )
    done
    cd /rpm-code
    fpm -t rpm -s dir -n "$rpm_base" -v "$version" \
        --rpm-rpmbuild-define "_build_id_links none" \
        --rpm-use-file-permissions --rpm-auto-add-directories \
        "${exclude[@]}" \
        "${rpm_code_build_install_files[@]}"
    fpm -t rpm -s dir -n "$rpm_base_src" -v "$version" \
        --rpm-rpmbuild-define "_build_id_links none" \
        --rpm-use-file-permissions --rpm-auto-add-directories \
        "${exclude[@]}" \
        "$rpm_code_build_src_dir"
}

rpm_code_build_exclude_add() {
    local d=$1
    if [[ ! $d =~ ^/ ]]; then
        install_err "$d: must begin with a /"
    fi
    while [[ $d != / ]]; do
        if [[ ${rpm_code_build_exclude[$d]+1} ]]; then
            break
        fi
        rpm_code_build_exclude[$d]=1
        d=$(dirname "$d")
    done
}

rpm_code_install_rpm() {
    local base=$1
    if [[ ! ${rpm_code_install_dir:-} ]]; then
        return
    fi
    # Y2100
    local f="$(ls -t "$base"-20[0-9][0-9]*rpm | head -1)"
    # Contains multiple directories separated by spaces
    local c d l
    for d in $rpm_code_install_dir; do
        install -m 444 "$f" "$d/"
        for c in dev alpha; do
            l="$d/$base-$c.rpm"
            rm -f "$l"
            ln -s "$f" "$l"
        done
    done
}

rpm_code_main() {
    if (( $# < 1 )); then
        install_err 'must supply code name, e.g. synergia'
    fi
    local code=$1
    local rpm_base build_args
    if [[ $1 == _build ]]; then
        shift
        rpm_code_build "$@"
        return
    fi
    umask 077
    install_tmp_dir
    : ${rpm_base:=rscode-$code}
    : ${rpm_base_src:=rscode-$code-src}
    : ${build_args:="$rpm_base $rpm_base_src $code"}
    docker run -i -u "$rpm_code_user" --network=host --rm -v "$PWD":/rpm-code "$rpm_code_image" <<EOF
. ~/.bashrc
set -e
cd /rpm-code
export install_server='$install_server' install_channel='$install_channel' install_debug='$install_debug'
radia_run rpm-code _build $build_args
EOF
    rpm_code_install_rpm "$rpm_base"
    rpm_code_install_rpm "$rpm_base_src"
}


rpm_code_main "${install_extra_args[@]}"
