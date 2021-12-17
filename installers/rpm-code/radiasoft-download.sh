#!/bin/bash

rpm_code_rpm_prefix=rscode

rpm_code_build() {
    local code=$1
    local args=( "$@" )
    # flag used by code.sh to know if inside this function
    local rpm_code_build=1
    local rpm_code_exclude_f=$PWD/exclude.txt
    install_source_bashrc
    _bivio_home_env_update -f
    install_source_bashrc
    install_url radiasoft/download installers/rpm-code
    install_script_eval codes.sh
    local rpm_code_root_dirs=( $HOME/.pyenv $HOME/.local )
    codes_main "${args[@]}"
    if [[ ${rpm_code_debug:-} ]]; then
        install_msg "Removing $HOME/rpmbuild"
        rm -rf "$HOME"/rpmbuild
    fi
    install_msg "$(date +%H:%M:%S) Generating $rpm_build_include_f"
    if rpm_code_is_common "$code"; then
        if [[ -e $rpm_code_exclude_f ]]; then
            install_err 'unexpected "codes_dependencies" in codes/common.sh'
        fi
        find "${rpm_code_root_dirs[@]}" | sort > "$rpm_build_include_f"
        touch "$rpm_build_depends_f"
    else
        if [[ ! -e $rpm_code_exclude_f ]]; then
            install_err 'missing "codes_dependencies", probably need: "codes_dependencies common"'
        fi
        find "${rpm_code_root_dirs[@]}" \
            ! -name pip-selfcheck.json ! -name '*.pyc' ! -name '*.pyo' \
            | sort | grep -vxFf "$rpm_code_exclude_f" - > "$rpm_build_include_f" || true
    fi
}

rpm_code_dependencies_done() {
    if [[ -e $rpm_code_exclude_f ]]; then
        install_err "duplicate call to rpm_code_dependencies_done"
    fi
    local i
    for i in "$@"; do
        # trilinos is huge (4GB) so don't add as a dependency
        # only needed to compile opal.
        # https://github.com/radiasoft/download/issues/140
        if [[ $i =~ trilinos ]]; then
            install_msg ignoring trilinos dependency
        else
            echo "$rpm_code_rpm_prefix-$i"
        fi
    done >> $rpm_build_depends_f
    find "${rpm_code_root_dirs[@]}" | sort > "$rpm_code_exclude_f"
}

rpm_code_is_common() {
    [[ $1 =~ ^(common|common_test)$ ]]
}

rpm_code_install_rpm() {
    local base=$1
    # Y2100
    local f="$(ls -t "$base"-20[0-9][0-9]*rpm | head -1)"
    # signing doesn't work, because rpmsign always prompts for password. People
    # have worked around it with an expect script, but that's just messed up.
    local dst=$rpm_code_install_dir/$f
    install -m 444 "$f" "$dst"
    install_msg "$dst"
    rpm_code_install_rpm=$dst
}

rpm_code_install_proprietary() {
    local rpm_base=$1
    local rpm_code_install_rpm
    rpm_code_install_rpm "$rpm_base"
    # Y2100
    local l="$rpm_code_install_dir/$rpm_base-dev.rpm"
    rm -f "$l"
    ln -s --relative "$rpm_code_install_rpm" "$l"
}

rpm_code_main() {
    if (( $# < 1 )); then
        install_err 'must supply code name, e.g. synergia'
    fi
    if [[ $1 == rpm_build_do ]]; then
        install_repo_eval rpm-build "$@"
        return
    fi
    install_tmp_dir
    local code=$1
    local args=( "$@" )
    # assert params and log
    install_info "rpm_code_install_dir=$rpm_code_install_dir"
    local base=$rpm_code_rpm_prefix-$code
    # these need to be space separated b/c substitution below
    local image=radiasoft/rpm-code
    if rpm_code_is_common "$code" || [[ $code == test ]]; then
        image=radiasoft/fedora
    fi
    if [[ ${rpm_code_debug:-} ]]; then
        # emulate what rpm-build does
        local rpm_build_guest_d=$PWD
        local rpm_build_include_f=$rpm_build_guest_d/include.txt
        local rpm_build_depends_f=$rpm_build_guest_d/depends.txt
        rpm_code_build "${args[@]}"
        return
    fi
    install_repo_eval rpm-build "$base" "$image" rpm-code rpm_code_build "${args[@]}"
    if [[ ${rpm_code_is_proprietary:-} ]]; then
        rpm_code_install_proprietary "$base"
    else
        rpm_code_install_rpm "$base"
        (umask 022; createrepo -q --update "$rpm_code_install_dir")
    fi
}

rpm_code_yum_dependencies() {
    if [[ -e $rpm_code_exclude_f ]]; then
        install_err 'must call codes_yum_dependencies before codes_dependencies'
    fi
    install_yum_install "$@"
    local i
    for i in "$@"; do
        echo "$i"
    done >> $rpm_build_depends_f
}
