#!/bin/bash

rpm_build_main() {
    if (( $# < 1 )); then
        install_err 'install_repo_eval only'
    fi
    if [[ $1 == _build ]]; then
        rpm_build_do "${@:2}"
        return
    fi
    local base=$1 image=$2 op=$3 args=( "${@:4}" )

    # assert params and log
    install_info "rpm_code_install_dir=$rpm_code_install_dir"
    umask 022
    install_tmp_dir
    : ${rpm_base:=$rpm_code_rpm_prefix-$code}
    : ${build_args:="$rpm_base $code"}
    : ${rpm_build_user:=vagrant}
    if [[ $EUID == 0 ]]; then
        # Needs to be owned by rpm_code_user
        chown "${rpm_code_user}:" "$PWD"
    fi

    pass image
    base
    extra_args
    installer name _build trick handled here?
    pwd is the same
    the mount directory is the same pass that in

    docker run -u root -i --network=host --rm -v "$PWD:$rpm_build_guest_d" "$rpm_build_image" <<EOF
set -euo pipefail
# SECURITY: not building a container so ok to add sudo
# POSIT: Same code in containers/bin/build.sh
echo "$rpm_code_user ALL=(ALL) NOPASSWD: ALL" | install -m 440 /dev/stdin /etc/sudoers.d/"$rpm_code_user"
chmod 4111 /usr/bin/sudo
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
