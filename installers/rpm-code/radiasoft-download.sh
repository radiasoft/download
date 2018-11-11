#!/bin/bash
# Copied from biviosoftware/rpm-perl. It's different, but rpm_code_install_rpm is the
# same
set -euo pipefail

rpm_code_rpm_prefix=rscode

rpm_code_guest_d=/rpm-code

rpm_code_build() {
    local rpm_base=$1
    local rpm_base_build=$2
    local code=$3
    local version=$(date -u +%Y%m%d.%H%M%S)
    # flag used by code.sh to know if inside this function
    local rpm_code_build=1
    local -A rpm_code_build_exclude
    local -a rpm_code_build_depends=()
    local rpm_code_build_include_f=$rpm_code_guest_d/files.txt
    # Avoid need for build_run_user_home_chmod_public
    # Make sure all files in RPMs are publicly executable
    # see radiasoft/download/installers/container-run
    echo 'umask 022' >> "$HOME"/.post_bivio_bashrc
    install_source_bashrc
    install_url radiasoft/download installers/rpm-code
    install_script_eval codes.sh
    codes_main "$code"
    rpm_code_build_exclude_add "$(dirname "$rpm_code_build_src_dir")"
    local start=$(date +%s)
    local deps=()
    local i
    for i in "${rpm_code_build_depends[@]}"; do
        deps+=( --depends "$i" )
    done
    local -A include_dirs
    local sorted=$rpm_code_build_include_f.sorted
    sort -u "$rpm_code_build_include_f" > "$sorted"
    local d
    while IFS="" read -r i; do
        d=$i
        while true; do
            d=$(dirname "$d")
            if [[ ${include_dirs[$d]+1} ]]; then
                break
            fi
            if [[ ${rpm_code_build_exclude[$d]+1} || $d == / ]]; then
                # include takes precedence over exclude so if we hit exclude
                # then it has to be included.
                printf '%s\n' "$i"
                break
            fi
        done
        if [[ -d $i ]]; then
            include_dirs[$i]=1
        fi
    done < "$sorted" > "$rpm_code_build_include_f"
    rm -f "$sorted"
    local exclude=()
    for i in "${!rpm_code_build_exclude[@]}"; do
        if [[ ! ${include_dirs[$i]+1} ]]; then
            exclude+=( --rpm-auto-add-exclude-directories "$i" )
        fi
    done
    install_info "fpm prep: $(( $(date +%s) - $start ))s"
    cd "$rpm_code_guest_d"
    fpm -t rpm -s dir -n "$rpm_base" -v "$version" \
        --rpm-rpmbuild-define "_build_id_links none" \
        --rpm-use-file-permissions --rpm-auto-add-directories \
        "${exclude[@]}" \
        "${deps[@]}" \
        --inputs "$rpm_code_build_include_f"
    fpm -t rpm -s dir -n "$rpm_base_build" -v "$version" \
        --rpm-rpmbuild-define "_build_id_links none" \
        --rpm-use-file-permissions --rpm-auto-add-directories \
        "${exclude[@]}" \
        "${deps[@]}" \
        "$rpm_code_build_src_dir"
}

rpm_code_build_include_add() {
    if [[ "$@" ]]; then
        local f
        for f in "$@"; do
            echo "$f"
        done >> "$rpm_code_build_include_f"
    else
        cat >> "$rpm_code_build_include_f"
    fi
}

rpm_code_build_exclude_add() {
    local d
    for d in "$@"; do
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
    done
}

rpm_code_install_rpm() {
    local base=$1
    # Y2100
    local f="$(ls -t "$base"-20[0-9][0-9]*rpm | head -1)"
    # signing doesn't work, because rpmsign always prompts for password. People
    # have worked around it with an expect script, but that's just messed up.
    install -m 444 "$f" "$rpm_code_yum_dir/$f"
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
    : ${rpm_base_build:=$rpm_code_rpm_prefix-$code-build}
    : ${build_args:="$rpm_base $rpm_base_build $code"}
    : ${rpm_code_image:=radiasoft/rpm-code}
    if [[ $code =~ ^(common|test)$ ]]; then
        rpm_code_image=radiasoft/fedora
    fi
    : ${rpm_code_user:=vagrant}
    if [[ $UID == 0 ]]; then
        # Needs to be owned by rpm_code_user
        chown "${rpm_code_user}:" "$PWD"
    fi
    docker run -u root -i --network=host --rm -v "$PWD:$rpm_code_guest_d" "$rpm_code_image" <<EOF
set -euo pipefail
echo "$rpm_code_user ALL=(ALL) NOPASSWD: ALL" | install -m 440 /dev/stdin /etc/sudoers.d/"$rpm_code_user"
su - "$rpm_code_user" <<EOF2
set -euo pipefail
cd '$rpm_code_guest_d'
export install_server='$install_server' install_channel='$install_channel' install_debug='$install_debug'
radia_run rpm-code _build $build_args
EOF2
EOF
    rpm_code_install_rpm "$rpm_base"
    rpm_code_install_rpm "$rpm_base_build"
    (umask 022; createrepo -q --update "$rpm_code_yum_dir")
}

rpm_code_main ${install_extra_args[@]+"${install_extra_args[@]}"}
