#!/bin/bash
# Copied from biviosoftware/rpm-perl. It's different, but rpm_code_install_rpm is the
# same
set -euo pipefail

rpm_code_rpm_prefix=rscode

rpm_code_guest_d=/rpm-code

rpm_code_build() {
    local rpm_base=$1
    local code=$2
    local version=$(date -u +%Y%m%d.%H%M%S)
    # flag used by code.sh to know if inside this function
    local rpm_code_build=1
    local rpm_code_build_desc=
    local rpm_code_build_include_f=$rpm_code_guest_d/include.txt
    local rpm_code_build_exclude_f=$rpm_code_guest_d/exclude.txt
    local rpm_code_build_depends_f=$rpm_code_guest_d/depends.txt
    local rpm_code_build_rsync_f=$rpm_code_guest_d/rsync.txt
    install_source_bashrc
    install_url radiasoft/download installers/rpm-code
    install_script_eval codes.sh
    local rpm_code_root_dirs=( $HOME/.pyenv $HOME/.local )
    codes_main "$code"
    if [[ ${rpm_code_debug:-} ]]; then
        install_msg "Removing $HOME/rpmbuild"
        rm -rf "$HOME"/rpmbuild
    fi
    mkdir -p "$HOME"/rpmbuild/{RPMS,BUILD,BUILDROOT,SPECS,tmp}
    cd "$HOME"/rpmbuild
    cat <<EOF > "$HOME"/.rpmmacros
%_topdir   $PWD
%_tmppath  %{_topdir}/tmp
EOF
    local r=$PWD/BUILDROOT
    local s=$PWD/SPECS/"$rpm_base".spec
    install_msg "$(date +%H:%M:%S) Generating $rpm_code_build_include_f"
    if rpm_code_is_common "$code"; then
        if [[ -e $rpm_code_build_exclude_f ]]; then
            install_err 'unexpected "codes_dependencies" in codes/common.sh'
        fi
        find "${rpm_code_root_dirs[@]}" | sort > "$rpm_code_build_include_f"
        touch "$rpm_code_build_depends_f"
    else
        if [[ ! -e $rpm_code_build_exclude_f ]]; then
            install_err 'missing "codes_dependencies", probably need: "codes_dependencies common"'
        fi
        find "${rpm_code_root_dirs[@]}" \
            ! -name pip-selfcheck.json ! -name '*.pyc' ! -name '*.pyo' \
            | sort | grep -vxFf "$rpm_code_build_exclude_f" - > "$rpm_code_build_include_f" || true
    fi
    install_msg "$(date +%H:%M:%S) Run: rpm-spec.PL"
    install_download rpm-spec.PL \
        | perl -w - "$rpm_code_guest_d" "$rpm_base" "$version" "$rpm_code_build_desc" > "$s"
    install_msg "$(date +%H:%M:%S) Run: rsync"
    rsync -aq --link-dest=/ --files-from="$rpm_code_build_rsync_f" / "$r"
    install_msg "$(date +%H:%M:%S) Run: rpmbuild"
    rpmbuild --buildroot "$r" -bb "$s"
    install_msg "$(date +%H:%M:%S) Done: rpmbuild"
    mv RPMS/x86_64/*.rpm "$rpm_code_guest_d"
}

rpm_code_dependencies_done() {
    if [[ -e $rpm_code_build_exclude_f ]]; then
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
    done >> $rpm_code_build_depends_f
    find "${rpm_code_root_dirs[@]}" | sort > "$rpm_code_build_exclude_f"
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
    local code=$1
    local f
    local rpm_base build_args
    if [[ $1 == _build ]]; then
        shift
        rpm_code_build "$@"
        return
    fi
    # assert params and log
    install_info "rpm_code_install_dir=$rpm_code_install_dir"
    umask 022
    install_tmp_dir
    : ${rpm_base:=$rpm_code_rpm_prefix-$code}
    : ${build_args:="$rpm_base $code"}
    : ${rpm_code_image:=radiasoft/rpm-code}
    if rpm_code_is_common "$code" || [[ $code == test ]]; then
        rpm_code_image=radiasoft/fedora
    fi
    : ${rpm_code_user:=vagrant}
    if [[ ${rpm_code_debug:-} ]]; then
        export rpm_code_guest_d=$PWD
        rpm_code_build $build_args
        return
    fi
    if [[ $EUID == 0 ]]; then
        # Needs to be owned by rpm_code_user
        chown "${rpm_code_user}:" "$PWD"
    fi
    docker run -u root -i --network=host --rm -v "$PWD:$rpm_code_guest_d" "$rpm_code_image" <<EOF
set -euo pipefail
echo "$rpm_code_user ALL=(ALL) NOPASSWD: ALL" | install -m 440 /dev/stdin /etc/sudoers.d/"$rpm_code_user"
su - "$rpm_code_user" <<EOF2
set -euo pipefail
cd '$rpm_code_guest_d'
$(install_vars_export)
radia_run rpm-code _build $build_args
EOF2
EOF
    if [[ ${rpm_code_is_proprietary:-} ]]; then
        rpm_code_install_proprietary "$rpm_base"
    else
        rpm_code_install_rpm "$rpm_base"
        (umask 022; createrepo -q --update "$rpm_code_install_dir")
    fi
}

rpm_code_yum_dependencies() {
    if [[ -e $rpm_code_build_exclude_f ]]; then
        install_err 'must call codes_yum_dependencies before codes_dependencies'
    fi
    install_yum_install "$@"
    local i
    for i in "$@"; do
        echo "$i"
    done >> $rpm_code_build_depends_f
}
