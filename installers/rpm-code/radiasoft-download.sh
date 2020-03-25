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
    local -a rpm_code_build_depends=()
    local rpm_code_build_include_f=$rpm_code_guest_d/include.txt
    local rpm_code_build_exclude_f=$rpm_code_guest_d/exclude.txt
    local rpm_code_build_depends_f=$rpm_code_guest_d/depends.txt
    local rpm_code_build_rsync_f=$rpm_code_guest_d/rsync.txt
    # Avoid need for build_run_user_home_chmod_public
    # Make sure all files in RPMs are publicly executable
    # see radiasoft/download/installers/container-run
    # The grep is only needed for dev-debug-build.sh
#    if ! grep -s -q '^umask 022' "$HOME"/.post_bivio_bashrc; then
#        echo 'umask 022' >> "$HOME"/.post_bivio_bashrc
#    fi
    install_source_bashrc
    install_url radiasoft/download installers/rpm-code
    install_script_eval codes.sh
    if [[ $code == test ]]; then
        codes_dependencies common-test
    fi
    if rpm_code_is_common "$code"; then
        echo "$HOME" > "$rpm_code_build_exclude_f"
    else
# "$(realpath "$(pyenv root)")" "${codes_dir[prefix]}"
        find $HOME/.pyenv $HOME/.local | sort > "$rpm_code_build_exclude_f"
    fi
    codes_main "$code"
    local i
    for i in "${rpm_code_build_depends[@]}"; do
        echo "$i"
    done > "$rpm_code_build_depends_f"
    rpm_code_build_exclude_add "$HOME"
    rm -rf "$HOME"/rpmbuild
    mkdir -p "$HOME"/rpmbuild/{RPMS,BUILD,BUILDROOT,SPECS,tmp}
    cd "$HOME"/rpmbuild
    cat <<EOF > "$HOME"/.rpmmacros
%_topdir   $PWD
%_tmppath  %{_topdir}/tmp
EOF
    local r=$PWD/BUILDROOT
    local s=$PWD/SPECS/"$rpm_base".spec
    install_msg "$(date +%M:%S) Generating $rpm_code_build_include_f"
    find $HOME/.pyenv $HOME/.local \
         ! -name pip-selfcheck.json ! -name '*.pyc' ! -name '*.pyo' \
         -print \
         | sort | grep -vxFf "$rpm_code_build_exclude_f" - > "$rpm_code_build_include_f"
    install_msg "$(date +%M:%S) Running rpm-spec.PL"
    install_download rpm-spec.PL \
        | perl -w - "$rpm_code_guest_d" "$rpm_base" "$version" "$rpm_code_build_desc" > "$s"
# --recursive
    install_msg "$(date +%M:%S) Running rsync"
    rsync -aq --link-dest=/ --files-from="$rpm_code_build_rsync_f" / "$r"
    install_msg "$(date +%M:%S) Running rpmbuild"
    rpmbuild --buildroot "$r" -bb "$s"
    mv RPMS/x86_64/*.rpm "$rpm_code_guest_d"
}

rpm_code_build_include_add() {
    if [[ "$@" ]]; then
        return
        local f
        for f in "$@"; do
            echo "$f"
        done >> "$rpm_code_build_include_f"
    else
        cat > /dev/null
#        cat >> "$rpm_code_build_include_f"
    fi
}

rpm_code_build_exclude_add() {
    return
    local d
    for d in "$@"; do
        if [[ ! $d =~ ^/ ]]; then
            install_err "rpm_code_build_exclude_add $d must be absolute path"
        fi
        echo "$d"
    done >> "$rpm_code_build_exclude_f"
}

rpm_code_is_common() {
    [[ $1 =~ ^(common|common-test)$ ]]
}

rpm_code_install_rpm() {
    local base=$1
    # Y2100
    local f="$(ls -t "$base"-20[0-9][0-9]*rpm | head -1)"
    # signing doesn't work, because rpmsign always prompts for password. People
    # have worked around it with an expect script, but that's just messed up.
    local dst=$rpm_code_yum_dir/$f
    install -m 444 "$f" "$dst"
    install_msg "$dst"
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
    install_info "rpm_code_yum_dir=$rpm_code_yum_dir"
    umask 077
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
    rpm_code_install_rpm "$rpm_base"
    (umask 022; createrepo -q --update "$rpm_code_yum_dir")
}
