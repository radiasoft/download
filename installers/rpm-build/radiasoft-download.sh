#!/bin/bash

export rpm_build_guest_d=/rpm-build

rpm_build_do() {
    export rpm_build_base=$1
    local op=$2
    local args=${@:3}
    # save the version here so closer to commit times, but unused by $op
    export rpm_build_version=$(date -u +%Y%m%d.%H%M%S)
    export rpm_build_include_f=$rpm_build_guest_d/include.txt
    export rpm_build_depends_f=$rpm_build_guest_d/depends.txt
    local rpm_build_desc
    install_source_bashrc
    $op $args
    install_url radiasoft/download installers/rpm-build
    mkdir -p "$HOME"/rpmbuild/{RPMS,BUILD,BUILDROOT,SPECS,tmp}
    cd "$HOME"/rpmbuild
    cat <<EOF > "$HOME"/.rpmmacros
%_topdir   $PWD
%_tmppath  %{_topdir}/tmp
EOF
    local r=$PWD/BUILDROOT
    local s=$PWD/SPECS/"$rpm_build_base".spec
    install_msg "$(date +%H:%M:%S) Run: rpm-spec.PL"
    export rpm_build_desc
    export rpm_build_rsync_f=$rpm_build_guest_d/rsync.txt
    install_download rpm-spec.PL | perl > "$s"
    install_msg "$(date +%H:%M:%S) Run: rsync"
    rsync -aq --link-dest=/ --files-from="$rpm_build_rsync_f" / "$r"
    install_msg "$(date +%H:%M:%S) Run: rpmbuild"
    rpmbuild --buildroot "$r" -bb "$s"
    install_msg "$(date +%H:%M:%S) Done: rpmbuild"
    install -m 444 RPMS/x86_64/*.rpm "$rpm_build_guest_d"
}

rpm_build_main() {
    if (( $# < 1 )); then
        install_err 'install_repo_eval only'
    fi
    if [[ $1 == rpm_build_do ]]; then
        rpm_build_do "${@:2}"
        return
    fi
    local base=$1 image=$2 repo=$3 op=$4 args="${*:5}"
    : ${rpm_build_user:=vagrant}
    if [[ $EUID == 0 && $rpm_build_user != root ]]; then
        # Needs to be owned by rpm_build_user
        chown "${rpm_build_user}:" "$PWD"
    fi
    $RADIA_RUN_OCI_CMD run -u root -i --network=host --rm -v "$PWD:$rpm_build_guest_d" "$image" <<EOF
set -euo pipefail
# SECURITY: not building a container so ok to add sudo
# POSIT: Same code in containers/bin/build.sh
echo "$rpm_build_user ALL=(ALL) NOPASSWD: ALL" | install -m 440 /dev/stdin /etc/sudoers.d/"$rpm_build_user"
chmod 4111 /usr/bin/sudo
su - "$rpm_build_user" <<'EOF2'
set -euo pipefail
cd '$rpm_build_guest_d'
$(install_vars_export)
radia_run $repo rpm_build_do $base $op $args
EOF2
EOF
}
