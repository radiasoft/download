#!/bin/bash

rpm_code_rpm_prefix=rscode

rpm_code_build() {
    declare code=$1
    # Used by install_script_eval
    declare install_extra_args=( "$@" )
    # flag used by code.sh to know if inside this function
    declare rpm_code_build=1
    declare rpm_code_exclude_f=$PWD/exclude.txt
    install_source_bashrc
    _bivio_home_env_update -f
    install_source_bashrc
    install_url radiasoft/download installers/rpm-code
    declare rpm_code_root_dirs=( $HOME/.pyenv $HOME/.declare )
    # install_extra_args set above
    install_script_eval codes.sh
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
    declare i
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
    [[ $1 == common ]]
}

rpm_code_install_rpm() {
    declare base=$1
    # Y2100
    declare f="$(ls -t "$base"-20[0-9][0-9]*rpm | head -1)"
    # signing doesn't work, because rpmsign always prompts for password. People
    # have worked around it with an expect script, but that's just messed up.
    declare dst=$rpm_code_install_dir/$f
    install -m 444 "$f" "$dst"
    install_msg "$dst"
    rpm_code_install_rpm=$dst
}

rpm_code_install_proprietary() {
    declare rpm_base=$1
    declare rpm_code_install_rpm
    rpm_code_install_rpm "$rpm_base"
    # Y2100
    declare l="$rpm_code_install_dir/$rpm_base-dev.rpm"
    rm -f "$l"
    ln -s --relative "$rpm_code_install_rpm" "$l"
}

rpm_code_main() {
    if (( $# < 1 )); then
        install_err 'must supply code name, e.g. srw'
    fi
    if [[ $1 == rpm_build_do ]]; then
        install_repo_eval rpm-build "$@"
        return
    fi
    install_tmp_dir
    declare code=$1
    declare args=( "$@" )
    # assert params and log
    install_info "rpm_code_install_dir=$rpm_code_install_dir"
    declare base=$rpm_code_rpm_prefix-$code
    # these need to be space separated b/c substitution below
    declare image=radiasoft/rpm-code
    if rpm_code_is_common "$code"; then
        image=radiasoft/fedora
    fi
    if [[ ${rpm_code_debug:-} ]]; then
        # emulate what rpm-build does
        declare rpm_build_guest_d=$PWD
        declare rpm_build_include_f=$rpm_build_guest_d/include.txt
        declare rpm_build_depends_f=$rpm_build_guest_d/depends.txt
        rpm_code_build "${args[@]}"
        return
    fi
    # POSIT: containers/bin/build-docker.sh._build_image_os_tag
    install_repo_eval rpm-build "$base" "$image:fedora-$install_version_fedora" rpm-code rpm_code_build "${args[@]}"
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
    declare i
    for i in "$@"; do
        echo "$i"
    done >> $rpm_build_depends_f
}
